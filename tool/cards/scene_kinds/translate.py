"""Rules for a `translate` scene: jargon set as a document, phrases retyped
in plain words.

The reader taps each marked phrase, it is retyped in plain words inside the
document, and a stub at the foot says why it was worded that way; at the end
the stub says what to watch for (lib/models/scenes/translate.dart has the
fields and an example). The limits are what fits on a small phone at the
smallest height the scene gets (270 px on the back of an asking card): the
whole document, in either reading, in about seven lines at 280 px wide, and
every stub line in three.

What this cannot check is whether the plain words are fair to the jargon.
That is the writer's rule: each `plain` and `why` is what the card's source
says the phrase means, not a guess at the writer's motives.
"""
from __future__ import annotations

HEAD_CHARS = 30      # the letterhead, small capitals on one line
REF_CHARS = 14       # beside it, at the right
TITLE_CHARS = 34     # one display line over the text
BODY_CHARS = (60, 260)
READ_CHARS = 280     # the body with every phrase in plain words
TEXT_CHARS = 44      # a phrase as printed; also the stub's quoted label
PLAIN_CHARS = 64
WHY_CHARS = 110      # three lines on the stub
ASK_CHARS = 64
WATCH_CHARS = 90
PHRASES = (2, 4)


def _text(v) -> bool:
    return isinstance(v, str) and bool(v.strip())


def check(scene: dict) -> list[str]:
    p: list[str] = []
    for key, limit in (("head", HEAD_CHARS), ("ask", ASK_CHARS), ("watch", WATCH_CHARS)):
        v = scene.get(key)
        if not _text(v):
            p.append(f"scene.{key}: missing")
        elif len(v.strip()) > limit:
            p.append(f"scene.{key}: {len(v.strip())} chars, over {limit}")
    for key, limit in (("ref", REF_CHARS), ("title", TITLE_CHARS)):
        v = scene.get(key, "")
        if not isinstance(v, str) or len(v.strip()) > limit:
            p.append(f"scene.{key}: a string of at most {limit} chars")

    body = scene.get("body")
    if not _text(body):
        return p + ["scene.body: missing"]
    body = body.strip()
    if not BODY_CHARS[0] <= len(body) <= BODY_CHARS[1]:
        p.append(f"scene.body: {len(body)} chars, not {BODY_CHARS[0]}–{BODY_CHARS[1]}")

    phrases = scene.get("phrases")
    if not isinstance(phrases, list) or not PHRASES[0] <= len(phrases) <= PHRASES[1]:
        return p + [f"scene.phrases: between {PHRASES[0]} and {PHRASES[1]}"]
    spans: list[tuple[int, int, str]] = []
    catches = 0
    for i, ph in enumerate(phrases):
        where = f"scene.phrases[{i}]"
        if not isinstance(ph, dict):
            p.append(f"{where}: not an object")
            continue
        for key, limit in (("text", TEXT_CHARS), ("plain", PLAIN_CHARS), ("why", WHY_CHARS)):
            v = ph.get(key)
            if not _text(v):
                p.append(f"{where}.{key}: missing")
            elif len(v.strip()) > limit:
                p.append(f"{where}.{key}: {len(v.strip())} chars, over {limit}")
        if "catch" in ph and not isinstance(ph["catch"], bool):
            p.append(f"{where}.catch: true or false")
        if ph.get("catch") is True:
            catches += 1
        text = ph.get("text")
        if not _text(text):
            continue
        text = text.strip()
        at = body.find(text)
        if at < 0:
            p.append(f"{where}.text: {text!r} is not in the body, word for word")
            continue
        if body.find(text, at + 1) >= 0:
            p.append(f"{where}.text: {text!r} is in the body twice")
        if _text(ph.get("plain")) and ph["plain"].strip().lower() == text.lower():
            p.append(f"{where}.plain: the same words as the phrase")
        spans.append((at, at + len(text), ph.get("plain", "").strip() if _text(ph.get("plain")) else text))
    spans.sort()
    for (a0, a1, _), (b0, _b1, _) in zip(spans, spans[1:]):
        if b0 < a1:
            p.append(f"scene.phrases: {body[a0:a1]!r} and {body[b0:_b1]!r} overlap")
    if catches > 1:
        p.append("scene.phrases: at most one catch")

    # The document must still fit once it is all in plain words.
    read, at = [], 0
    for s, e, plain in spans:
        read.append(body[at:s])
        read.append(plain)
        at = e
    read.append(body[at:])
    n = len("".join(read))
    if n > READ_CHARS:
        p.append(f"scene.body: {n} chars in plain words, over {READ_CHARS}")
    return p
