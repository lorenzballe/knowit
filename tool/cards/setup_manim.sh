#!/usr/bin/env bash
# Installs Manim (3Blue1Brown's animation engine) for the cards' "Video" format.
# Usage: bash tool/cards/setup_manim.sh   then   /opt/manim-venv/bin/manim -qh scene.py MyScene
set -euo pipefail
VENV="${MANIM_VENV:-/opt/manim-venv}"
if command -v apt-get >/dev/null 2>&1 && ! pkg-config --exists pangocairo 2>/dev/null; then
  (apt-get install -y -q libpango1.0-dev libcairo2-dev pkg-config ffmpeg \
    || sudo apt-get install -y -q libpango1.0-dev libcairo2-dev pkg-config ffmpeg)
fi
python3 -m venv "$VENV"
"$VENV/bin/pip" install -q --upgrade pip setuptools wheel
"$VENV/bin/pip" install -q manim
"$VENV/bin/python" -c "import manim; print('manim', manim.__version__, 'ready in $VENV')"
