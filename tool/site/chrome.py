"""The nav and the footer, stamped onto every page of the site.

    python3 tool/site/chrome.py          # rewrite them in site/*.html
    python3 tool/site/chrome.py --check  # exit 1 if any page has drifted

Six pages share the same header and footer. Kept by hand they drift — a
link added to one, a line changed on another — so they are written here
once and put onto every page between the markers the pages carry:
<!-- @header -->…<!-- /@header --> and <!-- @footer -->…<!-- /@footer -->.
The landing page links its own sections (#how); every other page links
back to them on the landing page (/#how).

It also writes the one link to the App Store, wherever a page has it — the
chrome, the hero, the plans, the redirect on /get — so that the provider
token below is set in one place and reaches all of them. The site's script
adds the campaign (ct) to each as the page loads.

Astute is on the App Store only. Android is coming, and until it is on
Google Play no page links there: its badge, /assets/badges/google-play.svg,
goes back beside Apple's on the day the listing is live, at
https://play.google.com/store/apps/details?id=com.astuto.app.
"""
import re
import sys
from pathlib import Path

SITE = Path(__file__).resolve().parents[2] / 'site'
APP_STORE = 'https://apps.apple.com/app/id6806852300'

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

BADGES = f'''<a href="{APP_STORE_LINK}"><img src="/assets/badges/app-store.svg" width="156" height="52" alt="Download on the App Store"></a>'''


def header(p, home):
    return f'''<!-- @header -->
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
      <div class="stores small">
        {BADGES}
      </div>
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
        <div class="stores small">
        {BADGES}
        </div>
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
