#!/usr/bin/env python3
"""Writes the wrapper that puts the server's words in place of the build's.

    python3 tool/remote/gen_strings.py           # write the wrapper
    python3 tool/remote/gen_strings.py --check   # fail if it is stale

Every string the app shows can be replaced from the server, without a
release: the `strings` part of the remote document, `remote/strings/<lang>.json`
(lib/remote/remote_strings.dart reads it). The app reads its strings from
AppLocalizations, which `flutter gen-l10n` writes from the arb files; this
writes `lib/l10n/remote_localizations.dart`, a subclass of it that answers
every string with the server's words when the document has some for it and
with the build's own otherwise. `context.l10n` hands it out (lib/l10n/l10n.dart).

It is written from two things, and holds them to each other:

* `lib/l10n/app_localizations.dart`, for every string's name and parameters,
  exactly as gen-l10n declared them, so the wrapper always compiles against
  the class it extends;
* `lib/l10n/app_en.arb`, the template, for how each placeholder is formatted:
  a number with a `format` goes through the very NumberFormat gen-l10n would
  have chosen, a date through the same DateFormat, so `{n}` in the server's
  words reads exactly as it does in the build's.

When the two disagree — a key added to the arb and gen-l10n not run — it
says so and writes nothing. So adding a string is: the arb files, then
`flutter gen-l10n`, then this. CI runs `--check` (.github/workflows/deploy.yml).

The output is put through `dart format`, so it is what the formatter would
leave; `dart` is found on PATH, beside `flutter`, or in FLUTTER_ROOT.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass, field
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
L10N = ROOT / "lib" / "l10n"
TEMPLATE = L10N / "app_en.arb"
DECLARED = L10N / "app_localizations.dart"
OUTPUT = L10N / "remote_localizations.dart"

# NumberFormat's constructors as gen-l10n calls them (flutter_tools'
# gen_l10n_types.dart): with the locale as the one positional argument, or
# as `locale:` beside the named optional parameters.
POSITIONAL_NUMBER_FORMATS = {"decimalPattern", "percentPattern", "scientificPattern"}
NAMED_NUMBER_FORMATS = {
    "compact", "compactCurrency", "compactSimpleCurrency", "compactLong", "currency",
    "decimalPatternDigits", "decimalPercentPattern", "simpleCurrency",
}
NUMBER_TYPES = {"int", "num", "double"}


class Stale(Exception):
    """The arb files and gen-l10n's output disagree, or say something this
    generator does not know how to format."""


@dataclass
class Param:
    type: str
    name: str


@dataclass
class Member:
    """One string of AppLocalizations: a getter, or a method and its parameters."""
    name: str
    getter: bool
    params: list[Param] = field(default_factory=list)


def languages() -> list[str]:
    """The languages the app ships, by their arb files: `app_<lang>.arb`."""
    return sorted(p.stem[len("app_"):] for p in L10N.glob("app_*.arb"))


def read_template() -> dict:
    return json.loads(TEMPLATE.read_text(encoding="utf-8"))


def template_keys(template: dict) -> list[str]:
    return [k for k in template if not k.startswith("@")]


def placeholders(template: dict, key: str) -> dict:
    """The placeholders the template declares for [key], by name."""
    meta = template.get("@" + key)
    if not isinstance(meta, dict):
        return {}
    found = meta.get("placeholders")
    return found if isinstance(found, dict) else {}


_GETTER = re.compile(r"^\s*String get (\w+);", re.M)
_METHOD = re.compile(r"^\s*String (\w+)\(([^)]*)\);", re.M)


def read_members(text: str | None = None) -> dict[str, Member]:
    """Every string AppLocalizations declares, by name, in its order."""
    if text is None:
        text = DECLARED.read_text(encoding="utf-8")
    start = text.find("abstract class AppLocalizations {")
    if start < 0:
        raise Stale(f"{DECLARED.relative_to(ROOT)} has no abstract class AppLocalizations")
    body = text[start:]
    found: list[tuple[int, Member]] = []
    for m in _GETTER.finditer(body):
        found.append((m.start(), Member(m.group(1), getter=True)))
    for m in _METHOD.finditer(body):
        params = []
        for raw in m.group(2).split(","):
            raw = raw.strip()
            if not raw:
                continue
            if raw.startswith("{") or raw.startswith("required"):
                raise Stale(f"{m.group(1)} takes named parameters, which this generator does not write")
            parts = raw.split()
            if len(parts) != 2:
                raise Stale(f"{m.group(1)}: cannot read the parameter {raw!r}")
            params.append(Param(parts[0], parts[1]))
        found.append((m.start(), Member(m.group(1), getter=False, params=params)))
    return {member.name: member for _, member in sorted(found, key=lambda f: f[0])}


def check_agreement(template: dict, members: dict[str, Member]) -> None:
    """Raises Stale when gen-l10n's class is not the one the template makes."""
    keys = template_keys(template)
    missing = [k for k in keys if k not in members]
    extra = [k for k in members if k not in template]
    if missing or extra:
        said = []
        if missing:
            said.append("not declared: " + ", ".join(missing[:8]) + (" …" if len(missing) > 8 else ""))
        if extra:
            said.append("declared but not in app_en.arb: " + ", ".join(extra[:8]))
        raise Stale(
            "lib/l10n/app_localizations.dart is not current with app_en.arb ("
            + "; ".join(said) + "): run flutter gen-l10n first"
        )
    for key in keys:
        member = members[key]
        declared = placeholders(template, key)
        if member.getter:
            if declared:
                raise Stale(f"{key} has placeholders in app_en.arb but is a getter: run flutter gen-l10n first")
            continue
        names = [p.name for p in member.params]
        if declared and set(names) != set(declared):
            raise Stale(
                f"{key}: app_localizations.dart takes {names}, app_en.arb declares "
                f"{sorted(declared)}: run flutter gen-l10n first"
            )


def _dart_string(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "\\'").replace("$", "\\$") + "'"


def _dart_literal(value) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return repr(value)
    if isinstance(value, str):
        return _dart_string(value)
    raise Stale(f"cannot write {value!r} as a Dart literal")


def shown_expression(key: str, param: Param, meta: dict) -> str | None:
    """How gen-l10n writes [param] into its string, as a Dart expression —
    or None where it writes the value as it is (`$name`)."""
    fmt = meta.get("format")
    if param.type in NUMBER_TYPES and fmt:
        if fmt in POSITIONAL_NUMBER_FORMATS:
            return f"intl.NumberFormat.{fmt}(localeName).format({param.name})"
        if fmt in NAMED_NUMBER_FORMATS:
            options = meta.get("optionalParameters") or {}
            named = "".join(f", {k}: {_dart_literal(v)}" for k, v in options.items())
            return f"intl.NumberFormat.{fmt}(locale: localeName{named}).format({param.name})"
        raise Stale(f"{key}: the number format {fmt!r} of {{{param.name}}} is not one gen-l10n knows")
    if param.type == "DateTime":
        if not fmt:
            raise Stale(f"{key}: the date {{{param.name}}} has no format")
        if meta.get("isCustomDateFormat") in (True, "true"):
            return f"intl.DateFormat({_dart_string(fmt)}, localeName).format({param.name})"
        first, *more = fmt.split("+")
        added = "".join(f".add_{part}()" for part in more)
        return f"intl.DateFormat.{first}(localeName){added}.format({param.name})"
    return None


def render(template: dict, members: dict[str, Member]) -> str:
    """The wrapper, before `dart format`."""
    lines: list[str] = []
    uses_intl = False
    for member in members.values():
        lines.append("  @override")
        if member.getter:
            lines.append(
                f"  String get {member.name} => _words.text('{member.name}') ?? _base.{member.name};"
            )
            lines.append("")
            continue
        declared = placeholders(template, member.name)
        params = ", ".join(f"{p.type} {p.name}" for p in member.params)
        call = ", ".join(p.name for p in member.params)
        args = ", ".join(f"'{p.name}': {p.name}" for p in member.params)
        shown = []
        for p in member.params:
            meta = declared.get(p.name) if isinstance(declared.get(p.name), dict) else {}
            expression = shown_expression(member.name, p, meta)
            if expression is not None:
                shown.append(f"'{p.name}': {expression}")
        tail = ""
        if shown:
            uses_intl = True
            tail = ", () => {" + ", ".join(shown) + "}"
        lines.append(
            f"  String {member.name}({params}) => "
            f"_words.format('{member.name}', localeName, {{{args}}}{tail}) ?? _base.{member.name}({call});"
        )
        lines.append("")
    header = [
        "// GENERATED by tool/remote/gen_strings.py from lib/l10n/app_en.arb and",
        "// lib/l10n/app_localizations.dart. Do not edit: run the generator, after",
        "// flutter gen-l10n, whenever a string is added. CI checks it is current.",
        "",
        "// ignore_for_file: type=lint",
        "",
    ]
    if uses_intl:
        header.append("import 'package:intl/intl.dart' as intl;")
        header.append("")
    header += [
        "import '../remote/remote_strings.dart';",
        "import 'app_localizations.dart';",
        "",
        "/// The build's own strings, with the server's words in their place",
        "/// wherever the remote document has some for this language. Made by",
        "/// withRemoteWords (lib/l10n/l10n.dart), once per document and language;",
        "/// every string it does not have words for is [_base]'s own.",
        "class RemoteLocalizations extends AppLocalizations {",
        "  RemoteLocalizations(this._base, this._words) : super(_base.localeName);",
        "",
        "  final AppLocalizations _base;",
        "  final RemoteWords _words;",
        "",
    ]
    return "\n".join(header + lines).rstrip() + "\n}\n"


def find_dart() -> str:
    """The dart executable: on PATH, beside flutter, or in FLUTTER_ROOT."""
    for candidate in (
        shutil.which("dart"),
        str(Path(shutil.which("flutter")).parent / "dart") if shutil.which("flutter") else None,
        str(Path(os.environ["FLUTTER_ROOT"]) / "bin" / "dart") if os.environ.get("FLUTTER_ROOT") else None,
        "/opt/flutter/bin/dart",
    ):
        if candidate and Path(candidate).exists():
            return candidate
    raise Stale("no dart to format the wrapper with: put flutter's bin on PATH, or set FLUTTER_ROOT")


def dart_format(source: str) -> str:
    """[source] as `dart format` leaves it, formatted inside the package so
    the package's own language version decides the style."""
    scratch = ROOT / ".dart_tool" / "gen_strings"
    scratch.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile("w", suffix=".dart", dir=scratch, delete=False, encoding="utf-8") as f:
        f.write(source)
        path = Path(f.name)
    try:
        done = subprocess.run(
            [find_dart(), "format", "--output=show", "--summary=none", str(path)],
            cwd=ROOT, capture_output=True, text=True,
        )
        if done.returncode != 0:
            raise Stale("dart format failed on the wrapper:\n" + done.stderr)
        return done.stdout
    finally:
        path.unlink(missing_ok=True)


def generate() -> str:
    template = read_template()
    members = read_members()
    check_agreement(template, members)
    return dart_format(render(template, members))


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--check", action="store_true", help="only report whether the wrapper is current")
    args = ap.parse_args(argv)
    try:
        text = generate()
    except Stale as e:
        print(e)
        print("nothing written")
        return 1
    current = OUTPUT.exists() and OUTPUT.read_text(encoding="utf-8") == text
    count = len(read_members())
    if args.check:
        if current:
            print(f"lib/l10n/remote_localizations.dart: current ({count} strings)")
            return 0
        print("stale: lib/l10n/remote_localizations.dart")
        print("run python3 tool/remote/gen_strings.py")
        return 1
    if current:
        print(f"lib/l10n/remote_localizations.dart: nothing to do ({count} strings)")
        return 0
    OUTPUT.write_text(text, encoding="utf-8")
    print(f"wrote lib/l10n/remote_localizations.dart ({count} strings)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
