"""Writes the two rows of cards under "Twenty subjects" on the site's first page.

Every subject is in each row once, so all twenty colours run past. The order comes from
the colour wheel the subject chips below the rows are laid out on: the top row steps 7
places round the wheel from one card to the next, the bottom row 9 places, from the other
side. Seven and nine share nothing with twenty, so each row meets every subject once and
two cards side by side are always far apart in colour; and as the rows run in opposite
directions, the pairs they make never repeat. Each subject has two real questions from
the bank, one for each row; the page's script picks which goes where, and where each row
starts, every time it opens, so the rows look different on every visit and are never
out of order.

    python3 tool/site/subjects_rows.py            # rewrites site/index.html in place
    python3 tool/site/subjects_rows.py --check    # fails if the page is not what it writes
"""
import html
import json
import re
import sys
from pathlib import Path

PAGE = Path(__file__).resolve().parents[2] / 'site' / 'index.html'

# Two questions per subject, as the bank asks them, short enough for the row's card.
QUESTIONS = {
    'Economics': ('Does foreign aid make poor countries grow faster?', 'Should cities scrap rules requiring parking spaces?'),
    'Sport': ('Why did gymnastics give up the perfect 10 in 2006?', 'Why do football clubs almost never disappear, even after going bankrupt?'),
    'Nature': ('Do trees really share food through a fungal network?', 'What fertilises the Amazon?'),
    'Science': ('Why is glass transparent to light but not to UV rays?', 'When a truck hits a car, which one pushes harder?'),
    'Maths': ("Why can't you flatten a balloon without tearing or stretching it?", 'What simple test can prove two knots are different?'),
    'Language': ('Why does the English word debt carry a b that nobody pronounces?', 'Is there a word every language shares?'),
    'Technology': ('Why do fast-charging claims so often stop at 80%, not 100%?', 'Why do the pages with the most links keep getting even more?'),
    'Space': ('Why does the Moon turn red during a lunar eclipse?', 'Where can a spacecraft park for free?'),
    'Philosophy': ('How wide is the present moment, as people experience it?', 'How did Sextus Empiricus say sceptics stumbled on peace of mind?'),
    'Cinema': ('Why are blockbusters orange and teal?', 'Why is a Foley stage built to sound like no room at all?'),
    'Psychology': ('Why does a downhill road appear to be uphill?', 'Does a light touch from your waiter change how much you tip?'),
    'Music': ('Why do so many recent pop hits credit five or more songwriters?', 'Where did Detroit techno get its name?'),
    'Weird facts': ('Who chooses one of the two heads of state of Andorra?', 'What has yielded the oldest DNA sequenced so far?'),
    'Art': ('Is a photo a record of what was there?', 'What kept Michelangelo from carving for most of 1518 to 1520?'),
    'Pop culture': ('Why did records get louder for thirty years?', 'How were television ratings actually measured?'),
    'Human body': ('What is falling in love for, biologically speaking?', 'How does high humidity prevent sweat from cooling us?'),
    'Medicine': ('What does a cigarette filter actually stop?', 'Should drug patents be shorter than twenty years?'),
    'Food': ('Why do onion vapors go straight for your eyes when you cut one?', 'Why has no saffron crocus ever been grown from its own seed?'),
    'History': ('What shape were the pyramids meant to stand for?', 'How did Japanese smiths learn to make such fine swords?'),
    'Life': ('How does your kitchen scale know what a kilogram is?', 'When choosing work, should you follow a passion you already have?'),
}
STEPS = ((7, 0), (9, 5))  # (step round the wheel, where on it the row starts)
CHIP = re.compile(r'<li class="chip"[^>]*--c:(#[0-9A-Fa-f]{6}); --ink:([0-9 ]+)"><svg class="mark" aria-hidden="true"><use href="#(subject-[a-z-]+)"/></svg>([^<]+)</li>')
ROWS = re.compile(r'(  <div class="marquee-mask">\n).*?(\n  </div>\n  <ul class="chips")', re.S)


def size(q: str) -> str:
    """The size the card starts at before the script fits it, so it reads without the script too."""
    return '30px' if len(q) <= 44 else '26px' if len(q) <= 56 else '23px'


def card(subject, colour, ink, mark, qs, row):
    q = qs[row]
    return (f'        <article class="deck-card paper" style="--c:{colour}; --ink:{ink}" data-qs="{html.escape(json.dumps(qs), quote=True)}">'
            f'<p class="label"><svg class="mark" aria-hidden="true"><use href="#{mark}"/></svg><span>{html.escape(subject)}</span></p>'
            f'<p class="deck-q" style="--fs:{size(q)}" data-fit-w="206" data-fit="18 30"><span>{html.escape(q)}</span></p></article>')


def rows(page: str) -> str:
    wheel = CHIP.findall(page)
    names = [w[3] for w in wheel]
    assert len(wheel) == 20 and set(names) == set(QUESTIONS), f'the chips name {names}'
    out = []
    for r, (step, start) in enumerate(STEPS):
        order = [wheel[(start + step * k) % 20] for k in range(20)]
        track = '\n'.join(card(n, c, ink, m, QUESTIONS[n], r) for c, ink, m, n in order)
        cls = 'marquee' + (' reverse' if r else '')
        out.append(f'    <div class="{cls}" aria-hidden="true" data-row="{r}">\n'
                   + ''.join(f'      <div class="marquee-track">\n{track}\n      </div>\n' for _ in range(2))
                   + '    </div>')
    return '\n'.join(out)


def main():
    page = PAGE.read_text(encoding='utf-8')
    new = ROWS.sub(lambda m: m.group(1) + rows(page) + m.group(2), page, count=1)
    assert new != page or '--check' in sys.argv or ROWS.search(page), 'the rows were not found'
    if '--check' in sys.argv:
        if new != page:
            sys.exit('site/index.html: the subject rows are not what tool/site/subjects_rows.py writes; run it')
        print('the subject rows are current')
        return
    PAGE.write_text(new, encoding='utf-8')
    print('wrote the two rows of twenty subjects')


if __name__ == '__main__':
    main()
