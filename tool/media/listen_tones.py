#!/usr/bin/env python3
"""Writes the two sounds Listen plays between a card's clips (lib/listen/).

    python3 tool/media/listen_tones.py

* `assets/audio/listen_think.m4a`: the pause to think, after a question and
  before its answer: one soft tone, a felt-mallet A at a fifth of full
  scale that dies away in about a second, then silence, 4.2 seconds in all.
* `assets/audio/listen_turn.m4a`: a breath between one card and the next,
  1.2 seconds of silence.

They are sounds rather than timers so that the phone's own queue plays
them: with the screen locked the app is not woken between clips, and a
pause it had to count itself would never end.

Made from numbers with the standard library, then encoded to AAC by ffmpeg,
which must be on PATH: a few kilobytes each, where WAV would be a hundred.
"""
from __future__ import annotations

import math
import shutil
import struct
import subprocess
import sys
import tempfile
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "audio"
RATE = 24_000


def tone(seconds: float) -> list[float]:
    """A soft struck A4: the fundamental and two quiet partials, a short
    attack and an exponential decay, then nothing until [seconds]."""
    out = []
    for i in range(int(seconds * RATE)):
        t = i / RATE
        attack = min(1.0, t / 0.018)
        decay = math.exp(-t / 0.32)
        s = (
            math.sin(2 * math.pi * 440 * t)
            + 0.22 * math.sin(2 * math.pi * 880 * t) * math.exp(-t / 0.18)
            + 0.06 * math.sin(2 * math.pi * 1320 * t) * math.exp(-t / 0.1)
        )
        out.append(0.2 * attack * decay * s / 1.28)
    return out


def silence(seconds: float) -> list[float]:
    return [0.0] * int(seconds * RATE)


def write(name: str, samples: list[float]) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        wav = Path(tmp) / f"{name}.wav"
        with wave.open(str(wav), "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(RATE)
            w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32767)) for s in samples))
        target = OUT / f"{name}.m4a"
        subprocess.run(
            ["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-c:a", "aac", "-b:a", "48k", "-ac", "1",
             "-map_metadata", "-1", "-movflags", "+faststart", str(target)],
            check=True,
        )
        print(f"{target.relative_to(ROOT)}: {len(samples) / RATE:.1f} s, {target.stat().st_size} bytes")


def main() -> int:
    if shutil.which("ffmpeg") is None:
        print("ffmpeg is needed on PATH", file=sys.stderr)
        return 1
    write("listen_think", tone(1.6) + silence(2.6))
    write("listen_turn", silence(1.2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
