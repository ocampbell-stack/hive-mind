#!/usr/bin/env bash
# dashboard.sh - Human-readable Hive Mind fleet status
# Usage: ./scripts/dashboard.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "============================================"
echo "        HIVE MIND FLEET DASHBOARD"
echo "        $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================"
echo ""

# Worktree status
echo "--- WORKTREES ---"
git -C "$REPO_DIR" worktree list 2>/dev/null || echo "  No worktrees found"
echo ""

# Git branches
echo "--- BRANCHES ---"
git -C "$REPO_DIR" branch -a 2>/dev/null | head -20
echo ""

# Beads task status
echo "--- OPEN TASKS ---"
cd "$REPO_DIR"
bd list 2>/dev/null || echo "  Beads not initialized"
echo ""

echo "--- READY TASKS ---"
bd ready 2>/dev/null || echo "  No ready tasks"
echo ""

# KB stats
echo "--- KNOWLEDGE BASE ---"
if [ -f "$REPO_DIR/knowledge-base/INDEX.md" ]; then
    head -3 "$REPO_DIR/knowledge-base/INDEX.md"
    echo ""
    KB_FILES=$(find "$REPO_DIR/knowledge-base" -name "*.md" ! -name "INDEX.md" ! -name "README.md" | wc -l | tr -d ' ')
    echo "  Content files: $KB_FILES"
else
    echo "  INDEX.md not found"
fi
echo ""

# Recent activity
echo "--- RECENT COMMITS ---"
git -C "$REPO_DIR" log --oneline --all -10 2>/dev/null || echo "  No commits yet"
echo ""

# Open PRs
echo "--- OPEN PRs ---"
cd "$REPO_DIR"
gh pr list 2>/dev/null || echo "  No open PRs (or not connected to remote)"
echo ""

echo "============================================"
