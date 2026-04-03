#!/usr/bin/env bash
# Usage: ./deploy-memory-bank.sh [target-directory]
# Copies memory-bank/ and .github/copilot-instructions.md into a target project.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-.}"

mkdir -p "$TARGET/memory-bank" "$TARGET/.github"
cp "$SCRIPT_DIR/memory-bank/"*.md "$TARGET/memory-bank/"
cp "$SCRIPT_DIR/.github/copilot-instructions.md" "$TARGET/.github/"

echo "Memory bank deployed to $TARGET"
echo "   Edit $TARGET/memory-bank/projectbrief.md to describe your project."
echo "   Edit $TARGET/memory-bank/productContext.md to describe why it exists."
echo "   The other files can be left as-is until your first pipeline run."
