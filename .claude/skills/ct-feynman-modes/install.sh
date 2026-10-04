#!/usr/bin/env bash
# Install the feynman skill by symlinking it where the agent looks for skills.
# Symlink (not copy) so `git pull` in this repo keeps the installed skill current.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<EOF
feynman skill installer

  ./install.sh              install to ~/.claude/skills/feynman   (all your projects)
  ./install.sh --project    install to ./.claude/skills/feynman   (current repo, committable)
  ./install.sh --uninstall  remove both install locations
EOF
}

target_dir() {
  if [ "${1:-}" = "--project" ]; then echo "$(pwd)/.claude/skills/feynman"
  else echo "$HOME/.claude/skills/feynman"; fi
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  --uninstall)
    for d in "$HOME/.claude/skills/feynman" "$(pwd)/.claude/skills/feynman"; do
      if [ -e "$d" ] || [ -L "$d" ]; then rm -rf "$d"; echo "removed $d"; fi
    done
    exit 0 ;;
esac

DST="$(target_dir "${1:-}")"
mkdir -p "$(dirname "$DST")"
rm -rf "$DST"
ln -s "$SRC" "$DST"
echo "linked $DST -> $SRC"
echo "invoke it with:  /feynman <topic>"
