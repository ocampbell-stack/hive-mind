#!/usr/bin/env bash
# dashboard.sh - Human-readable Hive Mind fleet status
# Usage: ./scripts/dashboard.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

echo "============================================"
echo "        HIVE MIND FLEET DASHBOARD"
echo "        $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================"
echo ""

# Worktree status
echo "--- WORKTREES ---"
git worktree list 2>/dev/null || echo "  No worktrees found"
echo ""

# Git branches
echo "--- BRANCHES ---"
git branch -a 2>/dev/null | head -20
echo ""

# Beads overview
echo "--- BEADS STATUS ---"
bd status 2>/dev/null || echo "  Beads not initialized"
echo ""

# Ready tasks (available for agents to pick up)
echo "--- READY TASKS ---"
bd ready 2>/dev/null || echo "  No ready tasks"
echo ""

# Blocked tasks (waiting on dependencies)
echo "--- BLOCKED TASKS ---"
bd blocked 2>/dev/null || echo "  No blocked tasks"
echo ""

# Epic progress (scope executions)
echo "--- EPIC PROGRESS ---"
bd epic status 2>/dev/null || echo "  No active epics"
echo ""

# Stale tasks (not updated recently)
echo "--- STALE TASKS ---"
bd stale 2>/dev/null || echo "  No stale tasks"
echo ""

# Dependency graph
echo "--- DEPENDENCY GRAPH ---"
bd graph --all --compact 2>/dev/null || echo "  No dependency graph (no open tasks with dependencies)"
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
git log --oneline --all -10 2>/dev/null || echo "  No commits yet"
echo ""

# Open PRs
echo "--- OPEN PRs ---"
gh pr list 2>/dev/null || echo "  No open PRs (or not connected to remote)"
echo ""

echo "============================================"
