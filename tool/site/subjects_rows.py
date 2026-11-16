"""Writes the two rows of cards under "Twenty subjects" on the site's first page.

Every subject is in each row once, so all twenty colours run past. The order is chosen for
the eye, measured in OKLab (a colour space spaced the way people see), not left to chance:

- one card light, the next dark, as far as twenty colours allow: the rhythm the eye reads
  as the rows run, and the cards' ink (dark on the light ones, white on the dark) keeps it;
- no two near-identical colours side by side (two blues, two reds), nor one card apart;
- no pair of opposite colours at the same lightness side by side (a red on a green as
  light as it): saturated complements of one lightness vibrate where they touch;
- the bottom row makes none of the pairs the top row makes, so the two read as two.

`--search` runs that score over shuffles (simulated annealing, fixed seeds) and prints the
best two rows; they are kept below as ROWS, so the page only changes when they are changed
on purpose. Each subject has two real questions from the bank, one for each row. The page's
script starts each row at a random card and swaps which question goes in which row, every
time it opens: the rows look new on every visit, and the order round them never breaks.

    python3 tool/site/subjects_rows.py            # rewrites site/index.html in place
    python3 tool/site/subjects_rows.py --check    # fails if the page is not what it writes
    python3 tool/site/subjects_rows.py --search   # scores the colours afresh, prints two rows
"""
import html
import json
import math
import random
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
# The two rows, as --search found them. The bottom one starts half way round, so that
# without the script the two rows do not open on the same colour.
ROWS = (
    ['Economics', 'Weird facts', 'Food', 'Cinema', 'Science', 'Medicine', 'Philosophy', 'History', 'Music', 'Language',
     'Art', 'Sport', 'Psychology', 'Life', 'Maths', 'Technology', 'Human body', 'Nature', 'Space', 'Pop culture'],
    ['Language', 'Human body', 'Philosophy', 'Life', 'Music', 'Maths', 'Food', 'Psychology', 'Science', 'Art',
     'Economics', 'Technology', 'Pop culture', 'Sport', 'Weird facts', 'History', 'Cinema', 'Nature', 'Medicine', 'Space'],
)
CHIP = re.compile(r'<li class="chip"[^>]*--c:(#[0-9A-Fa-f]{6}); --ink:([0-9 ]+)"><svg class="mark" aria-hidden="true"><use href="#(subject-[a-z-]+)"/></svg>([^<]+)</li>')
BLOCK = re.compile(r'(  <div class="marquee-mask">\n).*?(\n  </div>\n  <ul class="chips")', re.S)


def oklab(hexc):
    """Lightness, chroma and hue (degrees) of an sRGB colour, in OKLab."""
    r, g, b = (int(hexc[i:i + 2], 16) / 255 for i in (1, 3, 5))
    lin = lambda c: c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = lin(r), lin(g), lin(b)
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s
    A = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s
    B = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
    return L, math.hypot(A, B), math.degrees(math.atan2(B, A)) % 360


def score(order, colours, other=None):
    """How well a row (read round, as it loops) reads to the eye: higher is better."""
    P = {n: oklab(colours[n]) for n in order}
    mid = sorted(p[0] for p in P.values())[len(P) // 2]
    hue = lambda a, b: min(abs(P[a][2] - P[b][2]) % 360, 360 - abs(P[a][2] - P[b][2]) % 360)
    n, s = len(order), 0.0
    for k in range(n):
        a, b, c = order[k], order[(k + 1) % n], order[(k + 2) % n]
        h, dl = hue(a, b), abs(P[a][0] - P[b][0])
        if h < 45: s -= 6                                                    # near-identical neighbours
        if h > 150 and dl < 0.10 and P[a][1] > 0.12 and P[b][1] > 0.12: s -= 3  # complements that vibrate
        s += min(dl, 0.25) * 8 + min(h, 120) / 120                           # a step in light, a turn in hue
        if hue(a, c) < 35: s -= 2                                            # the same family one card later
        if (P[a][0] > mid) == (P[b][0] > mid) == (P[c][0] > mid): s -= 1.5   # three lights or darks running
    if other is not None:
        pairs = lambda q: {frozenset((q[k], q[(k + 1) % len(q)])) for k in range(len(q))}
        s -= 2 * len(pairs(order) & pairs(other))                            # the other row's pairs again
    return s


def search(colours):
    names = list(colours)

    def anneal(seed, other=None, steps=60000):
        rnd = random.Random(seed)
        o = names[:]
        rnd.shuffle(o)
        cur = score(o, colours, other)
        best = (cur, o[:])
        for t in range(steps):
            temp = 2.0 * (1 - t / steps) + 0.01
            i, j = rnd.sample(range(len(o)), 2)
            o[i], o[j] = o[j], o[i]
            s = score(o, colours, other)
            if s >= cur or rnd.random() < math.exp((s - cur) / temp):
                cur = s
            else:
                o[i], o[j] = o[j], o[i]
            if cur > best[0]:
                best = (cur, o[:])
        return best

    top = max((anneal(s) for s in range(12)), key=lambda x: x[0])
    bottom = max((anneal(100 + s, top[1]) for s in range(12)), key=lambda x: x[0])
    for name, (s, o) in (('top', top), ('bottom', bottom)):
        k = o.index('Economics')
        print(f'{name} ({s:.1f}):', json.dumps(o[k:] + o[:k]))


def size(q: str) -> str:
    """The size the card starts at before the script fits it, so it reads without the script too."""
    return '30px' if len(q) <= 44 else '26px' if len(q) <= 56 else '23px'


def card(subject, colour, ink, mark, qs, row):
    q = qs[row]
    return (f'        <article class="deck-card paper" style="--c:{colour}; --ink:{ink}" data-qs="{html.escape(json.dumps(qs), quote=True)}">'
            f'<p class="label"><svg class="mark" aria-hidden="true"><use href="#{mark}"/></svg><span>{html.escape(subject)}</span></p>'
            f'<p class="deck-q" style="--fs:{size(q)}" data-fit-w="206" data-fit="18 30"><span>{html.escape(q)}</span></p></article>')


def rows(chips) -> str:
    out = []
    for r, order in enumerate(ROWS):
        track = '\n'.join(card(n, chips[n][0], chips[n][1], chips[n][2], QUESTIONS[n], r) for n in order)
        cls = 'marquee' + (' reverse' if r else '')
        out.append(f'    <div class="{cls}" aria-hidden="true" data-row="{r}">\n'
                   + ''.join(f'      <div class="marquee-track">\n{track}\n      </div>\n' for _ in range(2))
                   + '    </div>')
    return '\n'.join(out)


def main():
    page = PAGE.read_text(encoding='utf-8')
    chips = {n: (c, ink, m) for c, ink, m, n in CHIP.findall(page)}
    assert len(chips) == 20 and set(chips) == set(QUESTIONS), f'the chips name {sorted(chips)}'
    assert all(sorted(r) == sorted(chips) for r in ROWS), 'each row must hold every subject once'
    if '--search' in sys.argv:
        search({n: v[0] for n, v in chips.items()})
        return
    assert BLOCK.search(page), 'the rows were not found on the page'
    new = BLOCK.sub(lambda m: m.group(1) + rows(chips) + m.group(2), page, count=1)
    if '--check' in sys.argv:
        if new != page:
            sys.exit('site/index.html: the subject rows are not what tool/site/subjects_rows.py writes; run it')
        print('the subject rows are current')
        return
    PAGE.write_text(new, encoding='utf-8')
    print('wrote the two rows of twenty subjects')


if __name__ == '__main__':
    main()
