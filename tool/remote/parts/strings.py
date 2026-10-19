"""Words that replace the build's own, one object per language
(remote/strings/<language>.json).

    remote/strings/it.json   {"reminderAskTitle": "Quando te lo ricordiamo?"}

Any string the app shows can be replaced: the app reads them all through a
wrapper (lib/l10n/remote_localizations.dart, written by
tool/remote/gen_strings.py) that answers with these words where there are
some and with the build's own otherwise. They are written as the arb files
write theirs, and held here to what the wrapper can say exactly as the
build would (lib/remote/remote_strings.dart):

* one file per language, named for one of the app's languages;
* a key of lib/l10n/app_en.arb, and words, not an empty string;
* the very placeholders the build's string has: every one, and no other;
* `{n, plural, …}` on a number, with the cases gen-l10n knows (`=0`, `=1`,
  `=2`, `zero`, `one`, `two`, `few`, `many`, `other`), `other` among them,
  none twice (`=1` and `one` are the same case);
* `{x, select, …}` on a string, with `other`, no case twice;
* no date or time argument (`{d, date, ::yMd}`): no arb file uses one, and
  the wrapper does not format them — the honest thing is to refuse them here
  rather than show something the build would not.
"""
from __future__ import annotations

import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

HERE = Path(__file__).resolve().parent
REMOTE_TOOLS = HERE.parent
if str(REMOTE_TOOLS) not in sys.path:
    sys.path.insert(0, str(REMOTE_TOOLS))

import gen_strings  # noqa: E402

# As gen-l10n's lexer has them (flutter_tools' message_parser.dart).
_NAME = re.compile(r"[a-zA-Z0-9|_]+")
_DIGITS = re.compile(r"[0-9]+")
_SPACE = re.compile(r"\s+")

PLURAL_CASES = {
    "=0": "zero", "=1": "one", "=2": "two",
    "zero": "zero", "one": "one", "two": "two", "few": "few", "many": "many", "other": "other",
}
NUMBER_TYPES = {"int", "num", "double"}


class Unreadable(ValueError):
    """Words the wrapper cannot read, and why."""


@dataclass
class Message:
    """What a message asks of its placeholders."""
    names: set[str] = field(default_factory=set)
    plurals: set[str] = field(default_factory=set)
    selects: set[str] = field(default_factory=set)


class _Reader:
    """Reads a message as lib/remote/remote_strings.dart does, and as
    gen-l10n does before it: outside braces everything is text; inside,
    space between the parts is passed over, and a case's words are a
    message again."""

    def __init__(self, text: str):
        self.s = text
        self.at = 0
        self.found = Message()

    def message(self, top: bool) -> None:
        while self.at < len(self.s):
            c = self.s[self.at]
            if c == "{":
                self.at += 1
                self.expression()
                continue
            if c == "}":
                if top:
                    raise Unreadable(f"a }} with no {{ before it, at {self.at}")
                return
            self.at += 1

    def skip(self) -> None:
        m = _SPACE.match(self.s, self.at)
        if m:
            self.at = m.end()

    def take(self, what: str) -> bool:
        self.skip()
        if self.s.startswith(what, self.at):
            self.at += len(what)
            return True
        return False

    def token(self, pattern: re.Pattern, expected: str) -> str:
        self.skip()
        m = pattern.match(self.s, self.at)
        if not m:
            raise Unreadable(f"expected {expected} at {self.at}")
        self.at = m.end()
        return m.group(0)

    def expression(self) -> None:
        name = self.token(_NAME, "a placeholder's name")
        self.found.names.add(name)
        if self.take("}"):
            return
        if not self.take(","):
            raise Unreadable(f"expected , or }} after {name}")
        kind = self.token(_NAME, "plural or select")
        if kind in ("date", "time"):
            raise Unreadable(
                f"{{{name}, {kind}, …}} is a {kind} argument, which the app does not format "
                f"from the server's words: write {{{name}}}, as the build passes it"
            )
        if kind not in ("plural", "select"):
            raise Unreadable(f"{kind!r} is neither plural nor select")
        (self.found.plurals if kind == "plural" else self.found.selects).add(name)
        if not self.take(","):
            raise Unreadable(f"expected , after {kind}")
        seen: set[str] = set()
        while not self.take("}"):
            if kind == "plural" and self.take("="):
                key = "=" + self.token(_DIGITS, "a number after =")
            else:
                key = self.token(_NAME, "a case")
            if kind == "plural":
                if key not in PLURAL_CASES:
                    raise Unreadable(f"{key} is not a plural case ({', '.join(PLURAL_CASES)})")
                category = PLURAL_CASES[key]
                if category in seen:
                    raise Unreadable(f"{{{name}, plural}} has the case {category} twice (=1 and one are the same)")
                seen.add(category)
            else:
                if key in seen:
                    raise Unreadable(f"{{{name}, select}} has the case {key} twice")
                seen.add(key)
            if not self.take("{"):
                raise Unreadable(f"expected {{ after the case {key}")
            self.message(top=False)
            if not self.take("}"):
                raise Unreadable(f"the case {key} of {name} is not closed")
        if "other" not in seen:
            raise Unreadable(f"{{{name}, {kind}}} has no other case")


def read(text: str) -> Message:
    """What [text] asks of its placeholders; raises Unreadable when the
    wrapper could not say it."""
    reader = _Reader(text)
    reader.message(top=True)
    return reader.found


def check(doc) -> list[str]:
    """The problems with this part, each a line a person can act on."""
    if doc is None:
        return []
    if not isinstance(doc, dict):
        return ["is one object per language"]
    if not doc:
        return []
    try:
        members = gen_strings.read_members()
    except gen_strings.Stale as e:
        return [str(e)]
    template = gen_strings.read_template()
    languages = gen_strings.languages()
    problems: list[str] = []
    for language, words in sorted(doc.items()):
        where = f"remote/strings/{language}.json"
        if language not in languages:
            problems.append(f"{where}: {language!r} is not one of the app's languages ({', '.join(languages)})")
            continue
        if not isinstance(words, dict):
            problems.append(f"{where}: is an object of arb keys and the words for them")
            continue
        for key, text in words.items():
            at = f"{where}: {key}"
            member = members.get(key)
            if member is None or key not in template:
                problems.append(f"{at}: is not a key of lib/l10n/app_en.arb")
                continue
            if not isinstance(text, str) or not text.strip():
                problems.append(f"{at}: is empty; to keep the build's own words, leave the key out")
                continue
            if "'''" in text:
                problems.append(f"{at}: holds ''' , which the build's copy of the document cannot carry")
                continue
            try:
                asked = read(text)
            except Unreadable as e:
                problems.append(f"{at}: {e}")
                continue
            params = {p.name: p.type for p in member.params}
            unknown = sorted(asked.names - params.keys())
            missing = sorted(params.keys() - asked.names)
            if unknown:
                has = ", ".join("{" + p + "}" for p in params) or "no placeholders"
                problems.append(f"{at}: {', '.join('{' + n + '}' for n in unknown)} is not one of its placeholders ({has})")
            if missing:
                problems.append(f"{at}: leaves out {', '.join('{' + n + '}' for n in missing)}, which the build's words say")
            for name in sorted(asked.plurals & params.keys()):
                if params[name] not in NUMBER_TYPES:
                    problems.append(f"{at}: {{{name}, plural}} counts a {params[name]}, not a number")
            for name in sorted(asked.selects & params.keys()):
                if params[name] != "String":
                    problems.append(f"{at}: {{{name}, select}} chooses by a {params[name]}, not a String")
    return problems
