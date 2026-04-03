#!/usr/bin/env bash
# Usage: ./install-memory-bank-hook.sh [target-directory]
# Installs a git post-commit hook that auto-updates memory-bank/activeContext.md
# and memory-bank/progress.md after every commit using the commit message as summary.
set -euo pipefail

TARGET="${1:-.}"
HOOKS_DIR="$TARGET/.git/hooks"

if [ ! -d "$HOOKS_DIR" ]; then
    echo "No .git/hooks directory found at $TARGET — is this a git repository?" >&2
    exit 1
fi

cat > "$HOOKS_DIR/post-commit" << 'HOOK'
#!/usr/bin/env bash
# Memory Bank semi-auto updater — runs after every git commit.
# Updates memory-bank/activeContext.md and progress.md using the commit message.

# Only run if memory-bank/ exists
if [ ! -d "memory-bank" ]; then
    exit 0
fi

# Get the last commit message
COMMIT_MSG=$(git log -1 --pretty=%B 2>/dev/null)
if [ -z "$COMMIT_MSG" ]; then
    exit 0
fi

echo "[memory-bank] Auto-updating from commit: ${COMMIT_MSG%%$'\n'*}"

copilot --yolo -p "Read memory-bank/activeContext.md and memory-bank/progress.md.

A git commit was just made with this message:
$COMMIT_MSG

Update memory-bank/activeContext.md and memory-bank/progress.md to reflect this change.
Move any newly committed items from 'In Progress' to 'Done' in progress.md.
Update 'Recent Changes' and 'Last Updated' in activeContext.md.

Write the full new content of each file using exactly this format:

### FILE: memory-bank/activeContext.md
[full file content]

### FILE: memory-bank/progress.md
[full file content]" 2>/dev/null | \
python3 -c "
import sys, re
content = sys.stdin.read()
pattern = re.compile(r'### FILE: (memory-bank/[^\s]+\.md)\n(.*?)(?=### FILE:|$)', re.DOTALL)
for m in pattern.finditer(content):
    path, body = m.group(1).strip(), m.group(2).strip()
    if path in ('memory-bank/activeContext.md', 'memory-bank/progress.md'):
        with open(path, 'w') as f:
            f.write(body + '\n')
        print(f'[memory-bank] Updated {path}')
"

# Stage and amend the commit if files changed
if ! git diff --quiet memory-bank/activeContext.md memory-bank/progress.md 2>/dev/null; then
    git add memory-bank/activeContext.md memory-bank/progress.md
    git commit --amend --no-edit --no-verify 2>/dev/null
    echo "[memory-bank] Amended commit with memory bank updates"
fi
HOOK

chmod +x "$HOOKS_DIR/post-commit"
echo "Memory bank post-commit hook installed at $HOOKS_DIR/post-commit"
echo "After each git commit, activeContext.md and progress.md will be auto-updated."
echo "To uninstall: rm $HOOKS_DIR/post-commit"
