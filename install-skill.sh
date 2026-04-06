#!/usr/bin/env bash
# Usage: ./install-skill.sh
# Installs all skills from skills/ into the superpowers plugin directory.
# Safe to re-run after skill updates.
set -euo pipefail

DEST="$HOME/.copilot/installed-plugins/superpowers-marketplace/superpowers/skills"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ ! -d "$SCRIPT_DIR/skills" ]; then
    echo "Error: no skills/ directory found in $SCRIPT_DIR" >&2
    exit 1
fi

mkdir -p "$DEST"

installed=0
for skill_dir in "$SCRIPT_DIR/skills"/*/; do
    [ -d "$skill_dir" ] || continue
    name=$(basename "$skill_dir")
    cp -r "$skill_dir" "$DEST/$name"
    echo "Installed: $name → $DEST/$name"
    installed=$((installed + 1))
done

if [ "$installed" -eq 0 ]; then
    echo "No skills found in $SCRIPT_DIR/skills/"
    exit 1
fi

echo ""
echo "Done. $installed skill(s) installed. Restart Copilot CLI to pick up new skills."
