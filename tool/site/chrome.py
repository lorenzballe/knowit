"""The nav and the footer, stamped onto every page of the site, in the
language the page is in.

    python3 tool/site/chrome.py          # rewrite them in site/*.html
    python3 tool/site/chrome.py --check  # exit 1 if any page has drifted

Eight pages share the same header and footer. Kept by hand they drift — a
link added to one, a line changed on another — so they are written here
once and put onto every page between the markers the pages carry:
<!-- @header -->…<!-- /@header --> and <!-- @footer -->…<!-- /@footer -->.
The landing page links its own sections (#how); every other page links
back to them on the landing page (/#how).

The site speaks English and Italian (LANGS). The landing page and /get are
written twice: in English at their address, as site/ has them, and in
Italian under /it/ (site/it/index.html, served at /it/), which
tool/site/i18n.py writes from the English page and the words in
tool/site/lang/it.json (TWINS). Every other page holds both languages at
one address and shows the reader's: the chrome carries each line twice, one
marked .l-en and one .l-it, and site.css hides the one not asked for. Which
one is asked for is the first thing every page decides, in its head before
anything is drawn (<!-- @lang -->…<!-- /@lang -->, lang_script): the one
the reader last chose with the switch in the nav, kept on the device under
astute.lang and nothing else, or else their browser's (navigator.language);
a page with a twin sends the reader to it. The words here are the chrome's
own, in both languages side by side (WORDS); a page's own words are its
own.

It also writes the one link to the App Store, wherever a page has it — the
chrome, the hero, the plans, the redirect on /get — so that the provider
token below is set in one place and reaches all of them. The site's script
adds the campaign (ct) to each as the page loads.

And it writes the store badges, Apple's and Google's side by side, wherever
the site offers the app: in the chrome, and in a page between the markers
<!-- @stores -->…<!-- /@stores -->. Each badge is the store's own artwork,
from the files the stores publish (site/assets/badges/): app-store.svg as
Apple serves it from its marketing guidelines, google-play.svg from Google's
badge files. The header carries one copy of each, as a symbol built here
from those files, and every badge on the page draws from it, inline: drawn
as part of the page, the artwork stays sharp at any size and any zoom, where
an image of it can be painted soft. A page that leaves the header's copy
out (a card's own page, which must stay small) draws from the same symbols
in site/assets/sprite.svg, which this writes too.

Beside them the header carries the subjects' own marks, one symbol each, so
that every card on the site names its subject as the app's cards do, with
the mark beside the name (<use href="#subject-space"/>). They are read from
the app's lib/data/subject_icons.dart, path for path, so a mark redrawn in
the app is redrawn here the next time this runs, and --check fails until it
has.

Astute is on Google Play too (since November 2026): with GOOGLE_PLAY_OPEN set,
Google's badge stands beside Apple's and leads to the listing. Unset, it is
marked "Coming soon" and leads nowhere.

The App Store listing is made but not live yet: apps.apple.com answers 404
for it in every storefront. Until APP_STORE_OPEN below says it is live, no
one is sent there. Apple's badge is marked "Coming soon" and leads to the
list on /get (#notify), where an iPhone owner leaves an email to be told
the day it is there (<!-- @notify -->…<!-- /@notify -->, written here, and
under the first screen's badges the same offer and a way to play today's
challenge in the browser, <!-- @iphone -->…<!-- /@iphone -->). Every
Download button (the links marked data-store, which the site's script
points at Google Play on Android and at the code to scan on a computer)
leads to /get instead of the App Store: /get sends an Android phone on to
Google Play, and keeps an iPhone on a page that says the app is on its way
(/*@appstore*/false/*/@appstore*/ in its script). And the words that say
where the app is say it as it is, free on Android and coming to iPhone,
wherever a page carries them, between <!-- @where -->…<!-- /@where --> (a
line) and <!-- @where-faq -->…<!-- /@where-faq --> (the question's answer).
Set APP_STORE_OPEN to True the day the listing is live, run this script and
tool/site/i18n.py, and every page offers both stores again.

The landing page's slim bar, the way to the prices and the store from
anywhere down a phone's long page, is written here too, for the same
reason: what it offers is where the app can be had (<!-- @slimbar -->).
"""
import html
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SITE = ROOT / 'site'
BADGES = SITE / 'assets' / 'badges'
SPRITE = SITE / 'assets' / 'sprite.svg'
SUBJECT_ICONS = ROOT / 'lib' / 'data' / 'subject_icons.dart'
APP_STORE = 'https://apps.apple.com/app/id6806852300'
GOOGLE_PLAY = 'https://play.google.com/store/apps/details?id=com.astuto.app'
GOOGLE_PLAY_OPEN = True

# Whether the App Store listing is live. The one line to change at launch:
# set it to True the day apps.apple.com stops answering 404 for the app,
# run this script (python3 tool/site/chrome.py) and tool/site/i18n.py, and
# commit what they rewrite. The challenge pages (tool/cards/challenge_pages.py)
# and the cards' own pages (tool/cards/card_pages.py) read it too.
APP_STORE_OPEN = False

# The languages the site speaks, English first: the site as it is written.
LANGS = ('en', 'it')

# The pages written once per language, by their English address: the
# English in site/, the others under /<lang>/ (tool/site/i18n.py). /sfida is
# written so too, when the site is put together (tool/cards/sfida_page.py).
TWINS = {'index.html': '/', 'get.html': '/get'}
GENERATED_TWINS = ('/sfida',)

# Where the language the reader chose with the switch is kept on their
# device: the one thing the site keeps there, and only once they choose.
LANG_KEY = 'astute.lang'

SUPPORT_EMAIL = 'thebalecompany@gmail.com'


def at(path: str, lang: str) -> str:
    """[path] (an address on the site, perhaps with a #part) in [lang]: the
    same for English, under /<lang>/ for the others — / is /it/, /get#notify
    is /it/get#notify."""
    if lang == 'en':
        return path
    if path == '/' or path.startswith('/#') or path.startswith('/?'):
        return f'/{lang}/' + path[1:]
    return f'/{lang}' + path


# The chrome's own words, in each language. The app's names are the app's
# (lib/l10n/app_it.arb): Esplora, Scarica, Elimina account.
WORDS = {
    'en': {
        'home': 'Astute — home',
        'main': 'Main',
        'how': 'How it works',
        'explore': 'Explore',
        'science': 'The science',
        'pricing': 'Pricing',
        'faq': 'FAQ',
        'download': 'Download',
        'menu': 'Menu',
        'support': 'Support',
        'langs13': 'App in 13 languages',
        'noads': 'No ads',
        'tagline': 'Five cards a day. A little sharper.',
        'foot': 'The app in thirteen languages, and no ads.',
        'footer': 'Footer',
        'product': 'Product',
        'help': 'Help',
        'delete': 'Delete your account',
        'write': 'Write to us',
        'legal': 'Legal',
        'privacy': 'Privacy',
        'terms': 'Terms',
        'cards': 'App in 13 languages · cards in English',
        'tm': ('Apple, the Apple logo and App Store are trademarks of Apple Inc. '
               'Google Play and the Google Play logo are trademarks of Google LLC.'),
        'soon': 'Coming soon',
        'app-store': 'Download on the App Store',
        'google-play': 'Get it on Google Play',
        'soon-label': '{label}: coming soon',
        'soon-notify': 'App Store: coming soon. Be told the day it is there',
        'switch': 'Italiano',
        'switch-short': 'IT',
        'switch-label': 'Il sito in italiano',
        'where-both': 'Free on iPhone and Android',
        'where-play': 'Free on Android · coming to iPhone',
        'where-play-s': 'Free on Android, and coming to iPhone',
        'where-apple': 'Free on iPhone · coming to Android',
        'where-apple-s': 'Free on iPhone, and coming to Android',
        'faq-both': ('Yes. Astute is on the App Store for iPhone and on Google Play '
                     'for Android, with the same cards every morning.'),
        'faq-play': ('On Android, yes: Astute is on Google Play. The iPhone app is on its '
                     'way to the App Store, with the same cards every morning; until it is there, the '
                     'App Store has no page for it. <a href="{notify}">Leave your email</a> and we '
                     'will tell you the day it is.'),
        'faq-apple': ('On iPhone, yes: Astute is on the App Store. The Android app is on its '
                      'way to Google Play, with the same cards every morning.'),
        'notify-title': 'On iPhone?',
        'notify-lede': ('The iPhone app is on its way to the App Store. Leave your email and we will '
                        'write to you once, the day it is there.'),
        'notify-label': 'Your email',
        'notify-placeholder': 'name@example.com',
        'notify-go': 'Notify me when it’s on iPhone',
        'notify-fine': 'For that one email alone, and then the address is deleted.',
        'notify-how': 'How we keep it',
        'notify-privacy': '/privacy#iphone-list',
        'notify-bad': 'Check the address: something seems to be missing.',
        'notify-fail': 'That did not go through. Try again in a moment.',
        'notify-sending': 'Sending…',
        'notify-done': 'You’re on the list.',
        'notify-done-line': 'We will write to you once, the day Astute is on the App Store.',
        'notify-noscript': 'Write to {email} and we will tell you the day it is there.',
        'notify-try': 'Try today’s challenge in your browser',
        'iphone-notify': 'On iPhone? Be told the day it’s there',
        'slim': 'Get Astute',
        'slim-notify': 'Notify me',
    },
    'it': {
        'home': 'Astute — home',
        'main': 'Principale',
        'how': 'Come funziona',
        'explore': 'Esplora',
        'science': 'La scienza',
        'pricing': 'Prezzi',
        'faq': 'Domande',
        'download': 'Scarica',
        'menu': 'Menu',
        'support': 'Assistenza',
        'langs13': 'App in 13 lingue',
        'noads': 'Niente pubblicità',
        'tagline': 'Cinque carte al giorno. Un po’ più svegli.',
        'foot': 'L’app in tredici lingue, e niente pubblicità.',
        'footer': 'Piè di pagina',
        'product': 'Prodotto',
        'help': 'Aiuto',
        'delete': 'Elimina l’account',
        'write': 'Scrivici',
        'legal': 'Note legali',
        'privacy': 'Privacy',
        'terms': 'Termini',
        'cards': 'App in 13 lingue · carte in inglese',
        'tm': ('Apple, il logo Apple e App Store sono marchi di Apple Inc. '
               'Google Play e il logo Google Play sono marchi di Google LLC.'),
        'soon': 'In arrivo',
        'app-store': 'Scarica su App Store',
        'google-play': 'Disponibile su Google Play',
        'soon-label': '{label}: in arrivo',
        'soon-notify': 'App Store: in arrivo. Fatti avvisare il giorno in cui c’è',
        'switch': 'English',
        'switch-short': 'EN',
        'switch-label': 'The site in English',
        'where-both': 'Gratis su iPhone e Android',
        'where-play': 'Gratis su Android · presto su iPhone',
        'where-play-s': 'Gratis su Android, e presto su iPhone',
        'where-apple': 'Gratis su iPhone · presto su Android',
        'where-apple-s': 'Gratis su iPhone, e presto su Android',
        'faq-both': ('Sì. Astute è sull’App Store per iPhone e su Google Play per Android, '
                     'con le stesse carte ogni mattina.'),
        'faq-play': ('Su Android sì: Astute è su Google Play. L’app per iPhone sta arrivando '
                     'sull’App Store, con le stesse carte ogni mattina; finché non c’è, sull’App Store '
                     'non ha ancora una pagina. <a href="{notify}">Lasciaci la tua email</a> e ti '
                     'avvisiamo il giorno in cui arriva.'),
        'faq-apple': ('Su iPhone sì: Astute è sull’App Store. L’app per Android sta arrivando su '
                      'Google Play, con le stesse carte ogni mattina.'),
        'notify-title': 'Hai un iPhone?',
        'notify-lede': ('L’app per iPhone sta arrivando sull’App Store. Lasciaci la tua email: ti '
                        'scriviamo una volta sola, il giorno in cui c’è.'),
        'notify-label': 'La tua email',
        'notify-placeholder': 'nome@esempio.it',
        'notify-go': 'Avvisami quando arriva su iPhone',
        'notify-fine': 'Serve solo per quell’email, poi l’indirizzo viene cancellato.',
        'notify-how': 'Come lo conserviamo',
        'notify-privacy': '/privacy#lista-iphone',
        'notify-bad': 'Controlla l’indirizzo: sembra che manchi qualcosa.',
        'notify-fail': 'Non è partita. Riprova tra un momento.',
        'notify-sending': 'Invio…',
        'notify-done': 'Sei nella lista.',
        'notify-done-line': 'Ti scriviamo una volta sola, il giorno in cui Astute arriva sull’App Store.',
        'notify-noscript': 'Scrivi a {email} e ti avvisiamo il giorno in cui c’è.',
        'notify-try': 'Prova la sfida di oggi nel browser',
        'iphone-notify': 'Hai un iPhone? Avvisami quando arriva',
        'slim': 'Scarica Astute',
        'slim-notify': 'Avvisami',
    },
}


def w(key: str, lang: str) -> str:
    return WORDS[lang][key]


def notify_link(lang: str) -> str:
    """Where Apple's badge leads while its listing is not live: the list on
    /get, in the page's language."""
    return at('/get', lang) + '#notify'


def where(sentence: bool = False, lang: str = 'en') -> str:
    """Where the app can be had: the stores that are live, as a line or,
    with [sentence], as words that read inside one."""
    if APP_STORE_OPEN and GOOGLE_PLAY_OPEN:
        return w('where-both', lang)
    if GOOGLE_PLAY_OPEN:
        return w('where-play-s' if sentence else 'where-play', lang)
    return w('where-apple-s' if sentence else 'where-apple', lang)


def where_faq(lang: str = 'en') -> str:
    """The answer to "Is it on iPhone and Android?", as the stores stand."""
    if APP_STORE_OPEN and GOOGLE_PLAY_OPEN:
        return f'<p class="faq-a">{w("faq-both", lang)}</p>'
    if GOOGLE_PLAY_OPEN:
        return f'<p class="faq-a">{w("faq-play", lang).format(notify=notify_link(lang))}</p>'
    return f'<p class="faq-a">{w("faq-apple", lang)}</p>'

# Apple's campaign links carry the account's provider token (pt) beside the
# campaign (ct). With it, App Store Connect counts what each campaign the site
# sends brings in; without it the ct is ignored and the links are plain ones.
# It is not in this repository. The owner finds it in App Store Connect → Apps
# → Astute → App Analytics → Acquisition → Campaigns → Generate a campaign
# link: the number after pt= in the link it makes. Put it here, run this
# script, and every App Store link on the site carries it.
APP_STORE_PROVIDER_TOKEN = ''

APP_STORE_LINK = APP_STORE + (
    f'?pt={APP_STORE_PROVIDER_TOKEN}&mt=8' if APP_STORE_PROVIDER_TOKEN else ''
)


def download(lang: str = 'en') -> str:
    """Where a Download button leads as written, before the site's script
    picks the visitor's store: the App Store once it is live, /get until
    then."""
    return APP_STORE_LINK if APP_STORE_OPEN else at('/get', lang)


DOWNLOAD = download('en')

# Each badge: the store's file, the frame of the artwork in it, and what the
# badge says, for whoever cannot see it (WORDS). Apple's file is framed on
# its badge; Google's leaves a pixel of empty canvas on either side, and its
# frame here is the badge's own edge, so that the two stand at exactly one
# height and the gap between them is the gap that shows.
BADGE_ART = {
    'app-store': ('app-store.svg', '0 0 119.66407 40'),
    'google-play': ('google-play.svg', '-0.11 0 239.17 70.87'),
}


def symbol(key):
    """A store's badge file as a symbol the page draws from: the same paths
    in the same colours, with its title and ids left out (a page draws each
    badge more than once), and its classes written onto the shapes as the
    styles they stand for, since a style sheet in the page's own SVG would
    reach the whole page."""
    name, frame = BADGE_ART[key]
    svg = (BADGES / name).read_text()
    rules = {}
    for sheet in re.findall(r'<style[^>]*>(.*?)</style>', svg, re.S):
        for selectors, body in re.findall(r'([^{}]+)\{([^}]*)\}', sheet):
            decls = ' '.join(d.strip() + ';' for d in body.split(';') if d.strip())
            for sel in selectors.split(','):
                sel = sel.strip()
                if sel.startswith('.'):
                    rules[sel[1:]] = (rules.get(sel[1:], '') + ' ' + decls).strip()
    art = svg[svg.index('>', svg.index('<svg')) + 1:svg.rindex('</svg>')]
    art = re.sub(r'<title>.*?</title>|<defs>.*?</defs>|<style[^>]*>.*?</style>', '', art, flags=re.S)
    art = re.sub(r'\s(?:id|data-name)="[^"]*"', '', art)
    art = re.sub(r'class="([^"]*)"', lambda m: 'style="' + ' '.join(rules[c] for c in m.group(1).split()) + '"', art)
    art = re.sub(r'>\s+<', '><', art).strip()
    return f'<symbol id="badge-{key}" viewBox="{frame}">{art}</symbol>'


def subject_marks():
    """The subjects' marks from the app's kSubjectIcons, as symbols named for
    the subject (subject-pop-culture). Only the path: the stroke, its weight
    and its colour are the page's to give (site.css, .mark), as the app gives
    them in subjectIconSvg()."""
    dart = SUBJECT_ICONS.read_text()
    table = dart[dart.index('kSubjectIcons'):]
    table = table[:table.index('};')]
    marks = re.findall(r"'([^']+)':\s*'([^']+)'", table)
    assert len(marks) >= 20, 'kSubjectIcons not where it was'
    return ''.join(
        f'<symbol id="subject-{name.lower().replace(" ", "-")}" viewBox="0 0 24 24"><path d="{path}"/></symbol>'
        for name, path in marks)


def sprite():
    return ('<svg class="symbols" width="0" height="0" aria-hidden="true" focusable="false">'
            + ''.join(symbol(key) for key in BADGE_ART) + subject_marks() + '</svg>')


def sprite_file() -> str:
    """The same symbols as a file of their own (site/assets/sprite.svg), for
    a page that draws them without carrying them: <use href="/assets/sprite.svg#badge-google-play"/>."""
    return ('<svg xmlns="http://www.w3.org/2000/svg">'
            + ''.join(symbol(key) for key in BADGE_ART) + subject_marks() + '</svg>\n')


def _art(key, src=''):
    _, frame = BADGE_ART[key]
    _, _, wd, ht = (float(n) for n in frame.split())
    return (f'<svg viewBox="{frame}" width="{round(52 * wd / ht)}" height="52" aria-hidden="true" focusable="false">'
            f'<use href="{src}#badge-{key}"/></svg>')


def _cls(lang, both):
    return f' l-{lang}' if both else ''


def _lang_attr(lang, both):
    return f' lang="{lang}"' if both and lang != 'en' else ''


def badge(key, href, lang='en', src='', both=False):
    """One badge, a link drawn from its symbol; sized by the page's CSS, at
    52 pixels high when there is none."""
    return (f'<a class="store store-{key}{_cls(lang, both)}"{_lang_attr(lang, both)} href="{href}" '
            f'aria-label="{w(key, lang)}">{_art(key, src)}</a>')


def coming(key, lang='en', src='', both=False):
    """A badge for a store the app is not in yet: the artwork, marked, and no
    link."""
    label = w('soon-label', lang).format(label=w(key, lang))
    return (f'<span class="store store-{key} store-soon{_cls(lang, both)}"{_lang_attr(lang, both)} role="img" '
            f'aria-label="{label}">{_art(key, src)}<span class="soon" aria-hidden="true">{w("soon", lang)}</span></span>')


def soon(key, href=None, lang='en', src='', both=False):
    """A badge for a store whose listing is made but not live: the artwork,
    quieter and marked, leading not to the store's empty page but to the
    list of those who want to be told the day it is live (/get#notify)."""
    href = notify_link(lang) if key == 'app-store' else href
    label = w('soon-notify', lang) if key == 'app-store' else w('soon-label', lang).format(label=w(key, lang))
    return (f'<a class="store store-{key} store-soon{_cls(lang, both)}"{_lang_attr(lang, both)} href="{href}" '
            f'aria-label="{label}">{_art(key, src)}<span class="soon" aria-hidden="true">{w("soon", lang)}</span></a>')


def _stores(lang, play_first, src, both):
    apple = (badge('app-store', APP_STORE_LINK, lang, src, both) if APP_STORE_OPEN
             else soon('app-store', None, lang, src, both))
    play = (badge('google-play', GOOGLE_PLAY, lang, src, both) if GOOGLE_PLAY_OPEN
            else coming('google-play', lang, src, both))
    return play + apple if play_first and GOOGLE_PLAY_OPEN and not APP_STORE_OPEN else apple + play


def stores(lang='en', play_first=False, src=''):
    """Both stores' badges, as they stand, in [lang] — or, with lang 'both',
    in each language, the reader's shown. With [play_first], the store the
    app is in comes first while only Google Play is live. [src] is where the
    badges' symbols are: the page's own header (''), or the sprite file."""
    if lang == 'both':
        return ''.join(_stores(lg, play_first, src, True) for lg in LANGS)
    return _stores(lang, play_first, src, False)


def say(key, lang):
    """A line of the chrome: in [lang], or in both, one span each."""
    if lang == 'both':
        return ''.join(f'<span class="l-{lg}"{_lang_attr(lg, True)}>{w(key, lg)}</span>' for lg in LANGS)
    return w(key, lang)


def say_where(lang, sentence=False):
    """where(), in [lang] or in both."""
    if lang == 'both':
        return ''.join(f'<span class="l-{lg}"{_lang_attr(lg, True)}>{where(sentence, lg)}</span>' for lg in LANGS)
    return where(sentence, lang)


def link(href_of, key, lang, cls='', extra=''):
    """A link of the chrome, in [lang]; or in both, one each, each to its own
    language's page. [href_of] gives a language's address."""
    if lang == 'both':
        return ''.join(f'<a class="{cls + " " if cls else ""}l-{lg}"{_lang_attr(lg, True)} href="{href_of(lg)}"{extra}>'
                       f'{w(key, lg)}</a>' for lg in LANGS)
    c = f' class="{cls}"' if cls else ''
    return f'<a{c} href="{href_of(lang)}"{extra}>{w(key, lang)}</a>'


def switch(lang, here):
    """The way to the other language, in the nav: on a page with a twin, the
    twin (the English one asked for with ?lang=en, which a browser in
    Italian would otherwise be sent on from); on a page in both, the other
    half of the same page (#it, #en), which the site's script shows in
    place."""
    def one(frm, to, href):
        return (f'<a class="lang-to{" l-" + frm if lang == "both" else ""}"{_lang_attr(frm, lang == "both")} '
                f'href="{href}" hreflang="{to}" data-lang-to="{to}" aria-label="{w("switch-label", frm)}">'
                f'<span class="lt-long" lang="{to}">{w("switch", frm)}</span>'
                f'<span class="lt-short" aria-hidden="true">{w("switch-short", frm)}</span></a>')
    if lang == 'both':
        return one('en', 'it', '#it') + one('it', 'en', '#en')
    if here is None:
        return ''
    if lang == 'en':
        return one('en', 'it', at(here, 'it'))
    return one('it', 'en', here + ('&' if '?' in here else '?') + 'lang=en')


SECTIONS = (('how', 'how'), ('explore', 'explore'), ('science', 'science'), ('pricing', 'pricing'), ('faq', 'faq'))


def _brand(lang, landing, foot=False):
    """The brand, leading home: the landing page's top, or the landing page
    in the page's language (in both, one each)."""
    pad = '        ' if foot else '    '
    img = ('<img src="/assets/icon.webp" width="30" height="30" alt="" loading="lazy">' if foot
           else '<img src="/assets/icon.webp" width="30" height="30" alt="">')
    inside = f'\n{pad}  {img}\n{pad}  <span>Astute</span>\n{pad}</a>'

    def one(href, lg, both):
        aria = '' if foot else f' aria-label="{w("home", lg)}"'
        return f'<a class="brand{" l-" + lg if both else ""}"{_lang_attr(lg, both)} href="{href}"{aria}>{inside}'
    if landing:
        return one('#top', lang, False)
    if lang == 'both':
        return ''.join(one(at('/', lg), lg, True) for lg in LANGS)
    return one(at('/', lang), lang, False)


def _section(landing):
    """A section of the landing page, from the page: its own, or the landing
    page's in the link's language."""
    return lambda anchor: (lambda lg: ('' if landing else at('/', lg)) + '#' + anchor)


def _page(path):
    """One of the pages in both languages, opened at the link's: /privacy,
    and /privacy#it."""
    return lambda lg: path + ('#' + lg if lg != 'en' else '')


def header(lang='en', here=None, landing=False):
    """The nav: the brand, the landing page's sections, the language switch,
    Download, and on a phone the menu. [lang] is the page's language, or
    'both'; [here] the page's English address, for the switch; [landing]
    when the page is the landing page itself, whose sections are its own."""
    sec = _section(landing)
    nav = '\n      '.join(link(sec(a), k, lang) for a, k in SECTIONS)
    menu = '\n      '.join([link(sec(a), k, lang) for a, k in SECTIONS] + [link(_page('/support'), 'support', lang)])
    dl = link(download, 'download', lang, cls='btn-download', extra=' data-store')
    one = 'en' if lang == 'both' else lang
    return f'''<!-- @header -->
{sprite()}
<header class="site-nav">
  <div class="progress" aria-hidden="true"></div>
  <nav aria-label="{w("main", one)}">
    {_brand(lang, landing)}
    <div class="nav-links" data-hide-mobile>
      {nav}
    </div>
    <div class="nav-actions">
      {switch(lang, here)}{dl}
      <button class="menu-toggle" id="menu-toggle" type="button" data-hide-desktop aria-expanded="false" aria-controls="mobile-menu" aria-label="{w("menu", one)}"><i></i></button>
    </div>
  </nav>
  <div id="mobile-menu" data-hide-desktop hidden>
    <div class="menu-links">
      {menu}
    </div>
    <div class="menu-foot">
      <p>{say_where(lang)} · {say("langs13", lang)} · {say("noads", lang)}</p>
      <div class="stores small">{stores(lang)}</div>
    </div>
  </div>
</header>
<!-- /@header -->'''


def footer(lang='en', here=None, landing=False):
    """The footer: the brand and where the app is, the stores, and the site's
    pages, in [lang] or in both."""
    sec = _section(landing)
    if lang == 'both':
        line = ''.join(f'<span class="l-{lg}"{_lang_attr(lg, True)}>{w("tagline", lg)} {where(True, lg)}. {w("foot", lg)}</span>'
                       for lg in LANGS)
    else:
        line = f'{w("tagline", lang)} {where(True, lang)}. {w("foot", lang)}'
    product = '\n          '.join(link(sec(a), k, lang) for a, k in SECTIONS)
    helps = '\n          '.join([link(_page('/support'), 'support', lang), link(_page('/delete-account'), 'delete', lang),
                                 link(lambda lg: f'mailto:{SUPPORT_EMAIL}', 'write', lang)])
    legal = '\n          '.join([link(_page('/privacy'), 'privacy', lang), link(_page('/terms'), 'terms', lang)])
    one = 'en' if lang == 'both' else lang
    return f'''<!-- @footer -->
<footer class="site-foot">
  <div class="foot-wrap">
    <div class="foot-top">
      <div class="foot-brand">
        {_brand(lang, landing, foot=True)}
        <p>{line}</p>
        <div class="stores small">{stores(lang)}</div>
      </div>
      <nav class="foot-cols" aria-label="{w("footer", one)}">
        <div>
          <h3>{say("product", lang)}</h3>
          {product}
        </div>
        <div>
          <h3>{say("help", lang)}</h3>
          {helps}
        </div>
        <div>
          <h3>{say("legal", lang)}</h3>
          {legal}
        </div>
      </nav>
    </div>
    <div class="foot-bottom">
      <span>© 2026 TheBaleCompany</span>
      <span>{say("cards", lang)}</span>
      <span class="tm">{say("tm", lang)}</span>
    </div>
  </div>
  <div class="foot-mark" aria-hidden="true">Astute</div>
</footer>
<!-- /@footer -->'''


def lang_script(lang: str, here: str | None = None) -> str:
    """The first thing every page runs, in its head, before anything is
    drawn: the page marked as read with a script (.js), the kind of device it
    is on (.android, .ios or .desktop, for what the page offers it), and the
    language to show. A page in one language ([lang] 'en' or 'it') with a
    twin sends the reader to the twin in the language they asked for: the
    one they last chose with the switch (kept under astute.lang, or given by
    the switch's ?lang=), else their browser's. A page in both ('both')
    shows the one its link names (#it, #en), else the same. Nothing about
    the reader is read beyond that, and nothing is kept but their choice."""
    lines = [
        "(function(){var h=document.documentElement,u=navigator.userAgent,s=null,k='" + LANG_KEY + "',"
        "q=/([?&])lang=(en|it)(&|$)/.exec(location.search);",
        "h.classList.add('js',/android/i.test(u)?'android':/iphone|ipad|ipod/i.test(u)||(/macintosh/i.test(u)&&navigator.maxTouchPoints>1)?'ios':'desktop');",
        "try{s=localStorage.getItem(k)}catch(e){}",
        "if(q){s=q[2];try{localStorage.setItem(k,s)}catch(e){}}",
        "var r=(q?location.search.replace(q[0],q[3]?q[1]:''):location.search)+location.hash,"
        "it=/^it(-|$)/i.test(navigator.language||'');",
        "var go=function(to){location.replace(to+r)};",
    ]
    clean = "if(q)history.replaceState(null,'',location.pathname+r);"
    if lang == 'en' and here:
        lines.append("if(s==='it'||(!s&&it)){go('" + at(here, 'it') + "');return}" + clean + "h.dataset.lang='en';")
    elif lang == 'it' and here:
        lines.append("if(s==='en'){go('" + here + "');return}" + clean + "h.dataset.lang='it';")
    else:
        lines.append(clean + "h.dataset.lang=location.hash==='#it'?'it':location.hash==='#en'?'en':s||(it?'it':'en');")
    lines.append('})();')
    return '<!-- @lang --><script>' + ''.join(lines) + '</script><!-- /@lang -->'


def alternates(here: str) -> str:
    """The page's twins, named for search engines: each language at its own
    address, and English for anyone else."""
    links = ''.join(f'<link rel="alternate" hreflang="{lg}" href="https://astutetheapp.com{at(here, lg)}">' for lg in LANGS)
    return (f'<!-- @alternates -->{links}<link rel="alternate" hreflang="x-default" '
            f'href="https://astutetheapp.com{here}"><!-- /@alternates -->')


def notify(lang: str) -> str:
    """The list for the iPhone, on /get: an email, to be told once, the day
    Astute is on the App Store (site/assets/notify.js keeps it in Firestore,
    firestore.rules says what it may hold). And beside it, today's challenge
    to play in the browser meanwhile. Nothing once the App Store is live."""
    if APP_STORE_OPEN:
        return '<!-- @notify --><!-- /@notify -->'
    e = lambda k: w(k, lang)  # noqa: E731
    mail = f'<a href="mailto:{SUPPORT_EMAIL}?subject=iPhone">{SUPPORT_EMAIL}</a>'
    return f'''<!-- @notify -->
<section class="notify" id="notify" aria-labelledby="notify-title">
  <h2 class="notify-title" id="notify-title">{e("notify-title")}</h2>
  <p class="notify-lede">{e("notify-lede")}</p>
  <form class="notify-form" data-notify data-lang="{lang}" data-bad="{html.escape(e("notify-bad"), quote=True)}" data-fail="{html.escape(e("notify-fail"), quote=True)}" data-sending="{html.escape(e("notify-sending"), quote=True)}" hidden novalidate>
    <label class="notify-label" for="notify-email">{e("notify-label")}</label>
    <div class="notify-row">
      <input class="notify-input" id="notify-email" name="email" type="email" autocomplete="email" inputmode="email" autocapitalize="off" spellcheck="false" maxlength="254" required placeholder="{e("notify-placeholder")}">
      <button class="btn btn-cream notify-go" type="submit">{e("notify-go")}</button>
    </div>
    <p class="notify-error" data-notify-error role="alert" hidden></p>
    <p class="notify-fine">{e("notify-fine")} <a href="{e("notify-privacy")}">{e("notify-how")}</a></p>
  </form>
  <div class="notify-done" data-notify-done tabindex="-1" hidden>
    <p class="notify-done-title">{e("notify-done")}</p>
    <p>{e("notify-done-line")}</p>
  </div>
  <noscript><p class="notify-lede">{e("notify-noscript").format(email=mail)}</p></noscript>
  <a class="notify-try" href="{at("/sfida", lang)}">{e("notify-try")} <span aria-hidden="true">→</span></a>
</section>
<!-- /@notify -->'''


def iphone(lang: str) -> str:
    """Under the first screen's badges, for anyone not on Android: the list
    for the iPhone while the App Store is not live, and today's challenge to
    play in the browser."""
    tries = f'<a href="{at("/sfida", lang)}">{w("notify-try", lang)}</a>'
    if APP_STORE_OPEN:
        return f'<!-- @iphone --><p class="hero-iphone">{tries}</p><!-- /@iphone -->'
    return (f'<!-- @iphone --><p class="hero-iphone"><a href="{notify_link(lang)}">{w("iphone-notify", lang)}</a>'
            f'<span class="sep" aria-hidden="true"> · </span>{tries}</p><!-- /@iphone -->')


def slimbar(lang: str) -> str:
    """The slim bar a phone gets once past the first screen: the prices, the
    questions, and the store — or, on an iPhone while the App Store is not
    live, the list (site/assets/main.js shows it and hides it)."""
    notify_a = ('' if APP_STORE_OPEN else
                f'<a class="slim-go slim-notify" href="{notify_link(lang)}">{w("slim-notify", lang)}</a>')
    return (f'<!-- @slimbar --><nav class="slimbar" aria-label="{w("slim", lang)}" data-slimbar>'
            f'<a class="slim-link" href="#pricing">{w("pricing", lang)}</a>'
            f'<a class="slim-link" href="#faq">{w("faq", lang)}</a>'
            f'<a class="slim-go slim-store" href="{download(lang)}" data-store>{w("download", lang)}</a>'
            f'{notify_a}</nav><!-- /@slimbar -->')


# Any link to the App Store a page holds, with whatever token it was given
# before, so that a new token replaces the old one everywhere.
APP_STORE_ANY = re.compile(re.escape(APP_STORE) + r'(?:\?pt=[^"\'&\s<>]*&mt=8)?')


def mode_of(name: str) -> tuple[str, str]:
    """A page of site/ as the chrome writes it: its language ('en' for a page
    with twins, 'both' for one holding both) and its English address."""
    if name in TWINS:
        return 'en', TWINS[name]
    return 'both', '/' + name[:-len('.html')]


def stamp(text, landing, lang='en', here=None):
    """[text], a page, with the chrome written onto it in [lang] ('en', 'it'
    or 'both'): the nav and the footer, the stores, where the app is, the
    language it opens in, its twins, and what the page offers an iPhone."""
    single = 'en' if lang == 'both' else lang
    text = re.sub(r'<!-- @header -->.*?<!-- /@header -->', lambda m: header(lang, here, landing), text, flags=re.S)
    text = re.sub(r'<!-- @footer -->.*?<!-- /@footer -->', lambda m: footer(lang, here, landing), text, flags=re.S)
    text = re.sub(r'<!-- @stores -->.*?<!-- /@stores -->', lambda m: '<!-- @stores -->' + stores(lang) + '<!-- /@stores -->', text, flags=re.S)
    text = re.sub(r'<!-- @where -->.*?<!-- /@where -->', lambda m: '<!-- @where -->' + say_where(lang) + '<!-- /@where -->', text, flags=re.S)
    text = re.sub(r'<!-- @where-faq -->.*?<!-- /@where-faq -->', lambda m: '<!-- @where-faq -->' + where_faq(single) + '<!-- /@where-faq -->', text, flags=re.S)
    text = re.sub(r'<!-- @lang -->.*?<!-- /@lang -->', lambda m: lang_script(lang, here), text, flags=re.S)
    if here and lang != 'both':
        text = re.sub(r'<!-- @alternates -->.*?<!-- /@alternates -->', lambda m: alternates(here), text, flags=re.S)
    text = re.sub(r'<!-- @notify -->.*?<!-- /@notify -->', lambda m: notify(single), text, flags=re.S)
    text = re.sub(r'<!-- @iphone -->.*?<!-- /@iphone -->', lambda m: iphone(single), text, flags=re.S)
    text = re.sub(r'<!-- @slimbar -->.*?<!-- /@slimbar -->', lambda m: slimbar(single), text, flags=re.S)
    text = re.sub(r'/\*@appstore\*/(?:true|false)/\*/@appstore\*/', lambda m: '/*@appstore*/' + ('true' if APP_STORE_OPEN else 'false') + '/*/@appstore*/', text)
    # What the page tells search engines the app runs on: the stores live.
    systems = ', '.join(s for s, live in (('Android', GOOGLE_PLAY_OPEN), ('iOS', APP_STORE_OPEN)) if live)
    text = re.sub(r'"operatingSystem": "[^"]*"', f'"operatingSystem": "{systems}"', text)
    text = APP_STORE_ANY.sub(lambda m: APP_STORE_LINK, text)
    # Every Download button, in the chrome and in the page, to its language's
    # Download.
    def to_download(m):
        tag = m.group(0)
        lg = 'it' if (lang == 'it' or (lang == 'both' and ' l-it' in tag)) else 'en'
        return re.sub(r'href="[^"]*"', lambda _: f'href="{download(lg)}"', tag, count=1)
    return re.sub(r'<a\b[^>]*\bdata-store\b[^>]*>', to_download, text)


def main():
    check = '--check' in sys.argv
    drifted = []
    for page in sorted(SITE.glob('*.html')):
        before = page.read_text()
        lang, here = mode_of(page.name)
        after = stamp(before, landing=page.name == 'index.html', lang=lang, here=here)
        if after != before:
            drifted.append(page.name)
            if not check:
                page.write_text(after)
    sprite_now = sprite_file()
    if not SPRITE.exists() or SPRITE.read_text() != sprite_now:
        drifted.append('assets/sprite.svg')
        if not check:
            SPRITE.write_text(sprite_now)
    if check and drifted:
        print('drifted: ' + ', '.join(drifted))
        sys.exit(1)
    print(('would rewrite: ' if check else 'rewrote: ') + (', '.join(drifted) or 'nothing'))


if __name__ == '__main__':
    main()
