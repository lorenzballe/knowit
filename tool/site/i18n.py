"""The site's pages in its other languages: each page that has a twin
(chrome.TWINS: the landing page and /get), written again under /<lang>/
from the English page as site/ has it and a table of its words.

    python3 tool/site/i18n.py            # writes site/it/index.html and site/it/get.html
    python3 tool/site/i18n.py --check    # exit 1 if a twin is not what this writes, or a word is not said
    python3 tool/site/i18n.py --missing  # the words not said yet, as JSON, in the order the pages show them

The English page stays the page: written and changed by hand, as it always
was. Its twin is never edited; it is written here, and the deploy stops
(--check) if it is not what this writes — which it is not the moment a word
on the English page changes and the table has not said it again.

The table is tool/site/lang/<lang>.json, one entry for each run of words
the English pages show a reader, as the page writes it (its &amp; and its
curly quotes), against the same said in the language by a person who writes
it, never word for word. A run is the words between two tags, so a sentence
with a link in it is three runs, said as three; the words in the attributes
a reader meets are runs too (alt, aria-label, a meta description, the
shelf's data-t-*), and so are, in the first screen's script, the pool's
drawings and the subjects' names. A run with no letters in it (a number, a
dash) is kept as it is unless the table says it otherwise, as it does a
price. Where a page's words cannot be said run by run, because the language
puts them in another order (the headline, set word by word), the table says
the whole element again under its id ("#hero-title"). What a reader cannot
see (comments, the scripts' code) is not said again, and nor are the
chrome's blocks, which tool/site/chrome.py writes in every language itself.

A card's own words (a question in the rows of subjects, class deck-q) are
the card's, in English, as the app shows them until the cards are
translated: kept, and marked lang="en".

In the twin the links to the site's other pages go to their own language:
/get to /it/get, the landing page's sections to /it/#how, the pages in both
languages to their Italian half (/privacy#it); its canonical address and
og:url are its own, and its og:locale the language's; and the app's
pictures are the app in the language, where site/assets/<lang>/ has them
(tool/site/shots.py). A new language is a new table, a line in LOCALES and
one in chrome.LANGS and chrome.WORDS.
"""
from __future__ import annotations

import json
import re
import sys
from html.parser import HTMLParser
from pathlib import Path

import chrome

ROOT = Path(__file__).resolve().parents[2]
SITE = ROOT / 'site'
TABLES = Path(__file__).resolve().parent / 'lang'
DOMAIN = 'https://astutetheapp.com'

# The languages written here, each with the locale it tells Open Graph.
LOCALES = {'en': 'en_GB', 'it': 'it_IT'}

# The attributes whose words a reader meets.
WORD_ATTRS = {'alt', 'aria-label', 'title', 'placeholder', 'aria-roledescription', 'aria-valuetext'}
# The metas whose content is words, by name or property.
WORD_METAS = {'description', 'og:title', 'og:description', 'og:image:alt', 'twitter:title', 'twitter:description'}
# The classes whose words are a card's own, kept in the card's language.
KEEP = {'deck-q'}
# The pages in both languages at one address: a link to one goes to its half.
BOTH = ('/privacy', '/terms', '/support', '/delete-account')
VOID = {'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', 'link', 'meta', 'source', 'track', 'wbr'}
CHROME_BLOCK = re.compile(r'<!-- @([\w-]+) -->.*?<!-- /@\1 -->', re.S)
# In an inline script, the words a reader meets: the first screen's pool of
# drawings, each read out by what it shows, and the subjects' names.
SCRIPT_WORDS = (
    re.compile(r'\["[a-z_]+-[a-z0-9-]+", "([^"]+)"\]'),
    re.compile(r"\b[a-z_]+: \['([^']+)', '#[0-9A-Fa-f]{6}'\]"),
)
ATTR = re.compile(r'\s([^\s=/>"\']+)\s*=\s*"([^"]*)"')
LETTER = re.compile(r'[^\W\d_]', re.U)


def key(raw: str) -> str:
    """A run as the table names it: its words, its spaces made one."""
    return re.sub(r'\s+', ' ', raw).strip()


class Runs(HTMLParser):
    """The runs of words on a page, each where it is in the page's text:
    (start, end, kind, raw) with kind 'text', 'attr', 'js' or 'json'; and
    the elements to say whole, and those whose words are kept."""

    def __init__(self, text: str, whole: set[str]):
        super().__init__(convert_charrefs=True)
        self.text = text
        self.whole = whole
        self.starts = [0] + [m.end() for m in re.finditer('\n', text)]
        self.skip = [(m.start(), m.end()) for m in CHROME_BLOCK.finditer(text)]
        self.stack: list[tuple[str, bool, str | None]] = []
        self.runs: list[tuple[int, int, str, str]] = []
        self.wholes: list[tuple[int, int, str]] = []
        self.kept_tags: list[int] = []
        self.script: str | None = None
        self.open_whole: tuple[str, int, int] | None = None

    def at(self) -> int:
        line, col = self.getpos()
        return self.starts[line - 1] + col

    def skipped(self, pos: int) -> bool:
        return any(a <= pos < b for a, b in self.skip)

    def keeping(self) -> bool:
        return any(k for _, k, _ in self.stack)

    def handle_starttag(self, tag, attrs):
        start = self.at()
        raw = self.get_starttag_text()
        a = dict(attrs)
        if not self.skipped(start):
            self._attrs(tag, raw, start, a)
        classes = set((a.get('class') or '').split())
        keep = bool(classes & KEEP)
        if keep and not self.skipped(start):
            self.kept_tags.append(start + 1 + len(tag))
        if tag == 'script':
            self.script = a.get('type') or 'js'
        ident = a.get('id')
        if ident and ident in self.whole and not self.skipped(start):
            self.open_whole = (ident, start + len(raw), len(self.stack))
        if tag not in VOID:
            self.stack.append((tag, keep, ident))

    def handle_startendtag(self, tag, attrs):
        start = self.at()
        if not self.skipped(start):
            self._attrs(tag, self.get_starttag_text(), start, dict(attrs))

    def handle_endtag(self, tag):
        if tag == 'script':
            self.script = None
        while self.stack:
            t, _, ident = self.stack.pop()
            if self.open_whole and len(self.stack) == self.open_whole[2] and ident == self.open_whole[0]:
                self.wholes.append((self.open_whole[1], self.at(), '#' + ident))
                self.open_whole = None
            if t == tag:
                break

    def handle_data(self, data):
        start = self.at()
        if self.skipped(start) or self.open_whole:
            return
        if self.script is not None:
            end = self.text.find('</script', start)
            body = self.text[start:end]
            if self.script == 'application/ld+json':
                for m in re.finditer(r'"description": "((?:[^"\\]|\\.)*)"', body):
                    self.runs.append((start + m.start(1), start + m.end(1), 'json', m.group(1)))
            elif self.script in ('js', 'text/javascript', 'module'):
                for pattern in SCRIPT_WORDS:
                    for m in pattern.finditer(body):
                        self.runs.append((start + m.start(1), start + m.end(1), 'js', m.group(1)))
            return
        if self.stack and self.stack[-1][0] == 'style':
            return
        end = self.text.find('<', start)
        end = len(self.text) if end < 0 else end
        raw = self.text[start:end]
        if raw.strip() and not self.keeping():
            self.runs.append((start, end, 'text', raw))

    def _attrs(self, tag, raw, start, a):
        meta = tag == 'meta' and (a.get('name') in WORD_METAS or a.get('property') in WORD_METAS)
        for m in ATTR.finditer(raw):
            name = m.group(1).lower()
            if name in WORD_ATTRS or name.startswith('data-t-') or (meta and name == 'content'):
                if m.group(2).strip():
                    self.runs.append((start + m.start(2), start + m.end(2), 'attr', m.group(2)))


def runs_of(text: str, whole: set[str]) -> Runs:
    parser = Runs(text, whole)
    parser.feed(text)
    parser.close()
    return parser


def says(raw: str) -> bool:
    """Whether a run has words to say: letters, not a number or a mark."""
    return bool(LETTER.search(raw))


def table(lang: str) -> dict[str, str]:
    return json.loads((TABLES / f'{lang}.json').read_text(encoding='utf-8'))


def js_string(value: str, quote: str) -> str:
    return value.replace('\\', '\\\\').replace(quote, '\\' + quote)


def relink(text: str, lang: str) -> str:
    """The links to the site's own pages, to their own language."""
    def one(m):
        href = m.group(1)
        path, _, part = href.partition('#')
        base, _, query = path.partition('?')
        if base in BOTH and not part:
            return f'href="{href}#{lang}"'
        if base == '/' or base in chrome.TWINS.values() or base in chrome.GENERATED_TWINS:
            return f'href="{chrome.at(href, lang)}"'
        return m.group(0)
    return re.sub(r'href="(/[^"]*)"', one, text)


def pictures(text: str, lang: str) -> str:
    """The app's pictures in [lang] where the camera took them in it
    (site/assets/<lang>/, tool/site/shots.py), the English ones elsewhere."""
    def one(m):
        name = m.group(1)
        if (SITE / 'assets' / lang / name).exists():
            return f'src="/assets/{lang}/{name}"'
        return m.group(0)
    return re.sub(r'src="/assets/([a-z0-9-]+\.webp)"', one, text)


def twin(name: str, lang: str, words: dict[str, str]) -> tuple[str, list[str], set[str]]:
    """The page [name] of site/ in [lang]: its text, the runs the table does
    not say, and the table's entries it used."""
    english = (SITE / name).read_text(encoding='utf-8')
    whole = {k[1:] for k in words if k.startswith('#')}
    found = runs_of(english, whole)
    edits: list[tuple[int, int, str]] = []
    missing: list[str] = []
    used: set[str] = set()
    for start, end, kind, raw in found.runs:
        k = key(raw) if kind == 'text' else raw
        if k not in words:
            if says(raw):
                missing.append(k)
            continue
        used.add(k)
        value = words[k]
        if kind == 'text':
            lead = raw[:len(raw) - len(raw.lstrip())]
            tail = raw[len(raw.rstrip()):]
            value = lead + value + tail
        elif kind == 'js':
            value = js_string(value, english[start - 1])
        elif kind == 'json':
            value = json.dumps(value, ensure_ascii=False)[1:-1]
        edits.append((start, end, value))
    for start, end, k in found.wholes:
        used.add(k)
        edits.append((start, end, words[k]))
    for at in found.kept_tags:
        edits.append((at, at, ' lang="en"'))
    out = english
    for start, end, value in sorted(edits, key=lambda e: (e[0], e[1]), reverse=True):
        out = out[:start] + value + out[end:]
    here = chrome.TWINS[name]
    out = out.replace('<html lang="en">', f'<html lang="{lang}">', 1)
    out = re.sub(r'(<link rel="canonical" href=")' + re.escape(DOMAIN) + r'([^"]*)"',
                 lambda m: m.group(1) + DOMAIN + chrome.at(m.group(2) or '/', lang) + '"', out, count=1)
    out = re.sub(r'(<meta property="og:url" content=")' + re.escape(DOMAIN) + r'([^"]*)"',
                 lambda m: m.group(1) + DOMAIN + chrome.at(m.group(2) or '/', lang) + '"', out, count=1)
    out = out.replace(f'<meta property="og:locale" content="{LOCALES["en"]}">',
                      f'<meta property="og:locale" content="{LOCALES[lang]}">', 1)
    out = out.replace(f'<meta property="og:locale:alternate" content="{LOCALES[lang]}">',
                      f'<meta property="og:locale:alternate" content="{LOCALES["en"]}">', 1)
    out = relink(out, lang)
    out = pictures(out, lang)
    out = chrome.stamp(out, landing=name == 'index.html', lang=lang, here=here)
    note = (f'<!-- Written by tool/site/i18n.py from site/{name} and tool/site/lang/{lang}.json: '
            f'change those and run it, never this. -->\n')
    out = out.replace('<!DOCTYPE html>\n', '<!DOCTYPE html>\n' + note, 1)
    return out, missing, used


def build(lang: str) -> tuple[dict[str, str], list[str], list[str]]:
    """Every twin in [lang]: {file: text}, the runs not said, and the table's
    entries no page uses any more."""
    words = table(lang)
    pages, missing, used = {}, [], set()
    for name in chrome.TWINS:
        text, miss, use = twin(name, lang, words)
        pages[f'{lang}/{name}'] = text
        missing += [m for m in miss if m not in missing]
        used |= use
    stale = [k for k in words if k not in used]
    return pages, missing, stale


def main(argv: list[str]) -> int:
    check, show = '--check' in argv, '--missing' in argv
    bad = False
    for lang in chrome.LANGS[1:]:
        pages, missing, stale = build(lang)
        if show:
            print(json.dumps({m: '' for m in missing}, ensure_ascii=False, indent=1))
            continue
        if missing:
            bad = True
            print(f'{lang}: {len(missing)} runs not said in tool/site/lang/{lang}.json (python3 tool/site/i18n.py --missing):')
            for m in missing[:20]:
                print('   ', m[:110])
        if stale:
            bad = True
            print(f'{lang}: {len(stale)} entries of tool/site/lang/{lang}.json no page shows any more:')
            for s in stale[:20]:
                print('   ', s[:110])
        for rel, text in pages.items():
            path = SITE / rel
            if check:
                if not path.exists() or path.read_text(encoding='utf-8') != text:
                    bad = True
                    print(f'site/{rel} is not what tool/site/i18n.py writes; run it')
            elif not missing:
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(text, encoding='utf-8')
                print(f'wrote site/{rel}')
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
