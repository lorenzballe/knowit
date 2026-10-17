"""The nav and the footer, stamped onto every page of the site.

    python3 tool/site/chrome.py          # rewrite them in site/*.html
    python3 tool/site/chrome.py --check  # exit 1 if any page has drifted

Eight pages share the same header and footer. Kept by hand they drift — a
link added to one, a line changed on another — so they are written here
once and put onto every page between the markers the pages carry:
<!-- @header -->…<!-- /@header --> and <!-- @footer -->…<!-- /@footer -->.
The landing page links its own sections (#how); every other page links
back to them on the landing page (/#how).

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
an image of it can be painted soft.

Beside them the header carries the subjects' own marks, one symbol each, so
that every card on the site names its subject as the app's cards do, with
the mark beside the name (<use href="#subject-space"/>). They are read from
the app's lib/data/subject_icons.dart, path for path, so a mark redrawn in
the app is redrawn here the next time this runs, and --check fails until it
has.

Android is coming to Google Play. Until the listing is open to everybody
(the closed test comes first), Google's badge stands beside Apple's marked
"Coming soon" and leads nowhere: a link to a listing nobody can see yet is a
Play Store page saying the app does not exist. The day it opens, set
GOOGLE_PLAY_OPEN and the badge becomes the link.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SITE = ROOT / 'site'
BADGES = SITE / 'assets' / 'badges'
SUBJECT_ICONS = ROOT / 'lib' / 'data' / 'subject_icons.dart'
APP_STORE = 'https://apps.apple.com/app/id6806852300'
GOOGLE_PLAY = 'https://play.google.com/store/apps/details?id=com.astuto.app'
GOOGLE_PLAY_OPEN = False

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

# Each badge: the store's file, the frame of the artwork in it, and what the
# badge says, for whoever cannot see it. Apple's file is framed on its badge;
# Google's leaves a pixel of empty canvas on either side, and its frame here
# is the badge's own edge, so that the two stand at exactly one height and
# the gap between them is the gap that shows.
BADGE_ART = {
    'app-store': ('app-store.svg', '0 0 119.66407 40', 'Download on the App Store'),
    'google-play': ('google-play.svg', '-0.11 0 239.17 70.87', 'Get it on Google Play'),
}


def symbol(key):
    """A store's badge file as a symbol the page draws from: the same paths
    in the same colours, with its title and ids left out (a page draws each
    badge more than once), and its classes written onto the shapes as the
    styles they stand for, since a style sheet in the page's own SVG would
    reach the whole page."""
    name, frame, _ = BADGE_ART[key]
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


def badge(key, href):
    """One badge, a link drawn from its symbol; sized by the page's CSS, at
    52 pixels high when there is none."""
    _, frame, label = BADGE_ART[key]
    _, _, w, h = (float(n) for n in frame.split())
    return (f'<a class="store store-{key}" href="{href}" aria-label="{label}">'
            f'<svg viewBox="{frame}" width="{round(52 * w / h)}" height="52" aria-hidden="true" focusable="false">'
            f'<use href="#badge-{key}"/></svg></a>')


def coming(key):
    """A badge for a store the app is not in yet: the artwork, marked, and no
    link."""
    _, frame, label = BADGE_ART[key]
    _, _, w, h = (float(n) for n in frame.split())
    return (f'<span class="store store-{key} store-soon" role="img" aria-label="{label}: coming soon">'
            f'<svg viewBox="{frame}" width="{round(52 * w / h)}" height="52" aria-hidden="true" focusable="false">'
            f'<use href="#badge-{key}"/></svg><span class="soon" aria-hidden="true">Coming soon</span></span>')


def stores():
    play = badge('google-play', GOOGLE_PLAY) if GOOGLE_PLAY_OPEN else coming('google-play')
    return badge('app-store', APP_STORE_LINK) + play


def header(p, home):
    return f'''<!-- @header -->
{sprite()}
<header class="site-nav">
  <div class="progress" aria-hidden="true"></div>
  <nav aria-label="Main">
    <a class="brand" href="{home}" aria-label="Astute — home">
      <img src="/assets/icon.webp" width="30" height="30" alt="">
      <span>Astute</span>
    </a>
    <div class="nav-links" data-hide-mobile>
      <a href="{p}#how">How it works</a>
      <a href="{p}#science">The science</a>
      <a href="{p}#pricing">Pricing</a>
      <a href="{p}#faq">FAQ</a>
    </div>
    <div class="nav-actions">
      <a class="btn-download" href="{APP_STORE_LINK}" data-store>Download</a>
      <button class="menu-toggle" id="menu-toggle" type="button" data-hide-desktop aria-expanded="false" aria-controls="mobile-menu" aria-label="Menu"><i></i></button>
    </div>
  </nav>
  <div id="mobile-menu" data-hide-desktop hidden>
    <div class="menu-links">
      <a href="{p}#how">How it works</a>
      <a href="{p}#science">The science</a>
      <a href="{p}#pricing">Pricing</a>
      <a href="{p}#faq">FAQ</a>
      <a href="/support">Support</a>
    </div>
    <div class="menu-foot">
      <p>Free on iPhone · Android coming soon · App in 13 languages · No ads</p>
      <div class="stores small">{stores()}</div>
    </div>
  </div>
</header>
<!-- /@header -->'''


def footer(p, home):
    return f'''<!-- @footer -->
<footer class="site-foot">
  <div class="foot-wrap">
    <div class="foot-top">
      <div class="foot-brand">
        <a class="brand" href="{home}">
          <img src="/assets/icon.webp" width="30" height="30" alt="" loading="lazy">
          <span>Astute</span>
        </a>
        <p>Five cards a day. A little sharper. Free on iPhone and coming to Android, the app in thirteen languages, and no ads.</p>
        <div class="stores small">{stores()}</div>
      </div>
      <nav class="foot-cols" aria-label="Footer">
        <div>
          <h3>Product</h3>
          <a href="{p}#how">How it works</a>
          <a href="{p}#science">The science</a>
          <a href="{p}#pricing">Pricing</a>
          <a href="{p}#faq">FAQ</a>
        </div>
        <div>
          <h3>Help</h3>
          <a href="/support">Support</a>
          <a href="/delete-account">Delete your account</a>
          <a href="mailto:thebalecompany@gmail.com">Write to us</a>
        </div>
        <div>
          <h3>Legal</h3>
          <a href="/privacy">Privacy</a>
          <a href="/terms">Terms</a>
        </div>
      </nav>
    </div>
    <div class="foot-bottom">
      <span>© 2026 TheBaleCompany</span>
      <span>App in 13 languages · cards in English</span>
      <span class="tm">Apple, the Apple logo and App Store are trademarks of Apple Inc. Google Play and the Google Play logo are trademarks of Google LLC.</span>
    </div>
  </div>
  <div class="foot-mark" aria-hidden="true">Astute</div>
</footer>
<!-- /@footer -->'''


# Any link to the App Store a page holds, with whatever token it was given
# before, so that a new token replaces the old one everywhere.
APP_STORE_ANY = re.compile(re.escape(APP_STORE) + r'(?:\?pt=[^"\'&\s<>]*&mt=8)?')


def stamp(text, landing):
    p, home = ('', '#top') if landing else ('/', '/')
    text = re.sub(r'<!-- @header -->.*?<!-- /@header -->', lambda m: header(p, home), text, flags=re.S)
    text = re.sub(r'<!-- @footer -->.*?<!-- /@footer -->', lambda m: footer(p, home), text, flags=re.S)
    text = re.sub(r'<!-- @stores -->.*?<!-- /@stores -->', lambda m: '<!-- @stores -->' + stores() + '<!-- /@stores -->', text, flags=re.S)
    return APP_STORE_ANY.sub(lambda m: APP_STORE_LINK, text)


def main():
    check = '--check' in sys.argv
    drifted = []
    for page in sorted(SITE.glob('*.html')):
        before = page.read_text()
        after = stamp(before, landing=page.name == 'index.html')
        if after != before:
            drifted.append(page.name)
            if not check:
                page.write_text(after)
    if check and drifted:
        print('drifted: ' + ', '.join(drifted))
        sys.exit(1)
    print(('would rewrite: ' if check else 'rewrote: ') + (', '.join(drifted) or 'nothing'))


if __name__ == '__main__':
    main()
