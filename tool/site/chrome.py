"""The nav and the footer, stamped onto every page of the site.

    python3 tool/site/chrome.py          # rewrite them in site/*.html
    python3 tool/site/chrome.py --check  # exit 1 if any page has drifted

Six pages share the same header and footer. Kept by hand they drift — a
link added to one, a line changed on another — so they are written here
once and put onto every page between the markers the pages carry:
<!-- @header -->…<!-- /@header --> and <!-- @footer -->…<!-- /@footer -->.
The landing page links its own sections (#how); every other page links
back to them on the landing page (/#how).
"""
import re
import sys
from pathlib import Path

SITE = Path(__file__).resolve().parents[2] / 'site'
APP_STORE = 'https://apps.apple.com/app/id6806852300'
PLAY = 'https://play.google.com/store/apps/details?id=com.astuto.app'

BADGES = f'''<a href="{APP_STORE}"><img src="/assets/badges/app-store.svg" width="156" height="52" alt="Download on the App Store"></a>
        <a href="{PLAY}"><img src="/assets/badges/google-play.png" width="175" height="52" alt="Get it on Google Play"></a>'''


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
      <a class="btn-download" href="{APP_STORE}" data-store>Download</a>
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
      <p>Free on iPhone and Android · 13 languages · No ads</p>
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
        <p>Five cards a day. A little sharper. Free on iPhone and Android, in thirteen languages, with no ads.</p>
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
      <span>Available in 13 languages</span>
      <span class="tm">Apple, the Apple logo and App Store are trademarks of Apple Inc. Google Play and the Google Play logo are trademarks of Google LLC.</span>
    </div>
  </div>
  <div class="foot-mark" aria-hidden="true">Astute</div>
</footer>
<!-- /@footer -->'''


def stamp(text, landing):
    p, home = ('', '#top') if landing else ('/', '/')
    text = re.sub(r'<!-- @header -->.*?<!-- /@header -->', lambda m: header(p, home), text, flags=re.S)
    text = re.sub(r'<!-- @footer -->.*?<!-- /@footer -->', lambda m: footer(p, home), text, flags=re.S)
    return text


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
