#!/usr/bin/env bash
# Usage: ./update-memory-bank.sh "summary of what you just did"
# Asks Copilot to update activeContext.md and progress.md based on a summary.
set -euo pipefail

SUMMARY="${1:-session update}"

if [ ! -d "memory-bank" ]; then
    echo "No memory-bank/ directory found. Run deploy-memory-bank.sh first." >&2
    exit 1
fi

copilot --yolo -p "Read all files in memory-bank/ in this order:
1. memory-bank/projectbrief.md
2. memory-bank/productContext.md
3. memory-bank/systemPatterns.md
4. memory-bank/techContext.md
5. memory-bank/activeContext.md
6. memory-bank/progress.md

Based on this session summary: '$SUMMARY'

Update memory-bank/activeContext.md and memory-bank/progress.md to reflect this work.
Write the full new content of each file using this format:

### FILE: memory-bank/activeContext.md
[full file content here]

### FILE: memory-bank/progress.md
[full file content here]"
