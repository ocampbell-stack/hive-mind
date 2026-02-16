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

# Recommended next actions
echo "--- RECOMMENDED ACTIONS ---"
_actions=0

# Check: agent worktrees not on their workspace branch
for _agent_dir in "$REPO_DIR"/../agent-*; do
    if [[ -d "$_agent_dir/.git" || -f "$_agent_dir/.git" ]]; then
        _agent_name=$(basename "$_agent_dir")
        _agent_short="${_agent_name#agent-}"
        _current=$(git -C "$_agent_dir" branch --show-current 2>/dev/null || echo "")
        _expected="$_agent_name/workspace"
        if [[ -n "$_current" && "$_current" != "$_expected" ]]; then
            echo "  -> $_agent_name is on '$_current' (expected: $_expected)"
            echo "     Run: ./scripts/cleanup.sh $_agent_short"
            _actions=$((_actions + 1))
        fi
    fi
done

# Check: local main out of sync with origin
_local_main=$(git rev-parse main 2>/dev/null || echo "")
_remote_main=$(git rev-parse origin/main 2>/dev/null || echo "")
if [[ -n "$_local_main" && -n "$_remote_main" && "$_local_main" != "$_remote_main" ]]; then
    echo "  -> Local main is out of sync with origin/main"
    echo "     Run: git pull --ff-only"
    _actions=$((_actions + 1))
fi

# Check: open PRs awaiting review
_pr_list=$(gh pr list --json number,title --jq '.[] | "#\(.number): \(.title)"' 2>/dev/null || echo "")
if [[ -n "$_pr_list" ]]; then
    _pr_count=$(echo "$_pr_list" | wc -l | tr -d ' ')
    echo "  -> $_pr_count open PR(s) awaiting review:"
    echo "$_pr_list" | while IFS= read -r _pr; do
        echo "     $_pr"
    done
    _actions=$((_actions + 1))
fi

# Check: shared infra needs syncing to public template
if [[ -d "$REPO_DIR/../hive-mind-main/.git" ]]; then
    _sync_output=$("$SCRIPT_DIR/sync-template.sh" --dry-run 2>&1 || true)
    if ! echo "$_sync_output" | grep -q "Already in sync"; then
        echo "  -> Shared infra differs from public template"
        echo "     1. Review:  ./scripts/sync-template.sh --dry-run"
        echo "     2. Verify:  ./scripts/sync-template.sh --diff"
        echo "     3. Sync:    ./scripts/sync-template.sh"
        _actions=$((_actions + 1))
    fi
fi

# Check: beads ready for assignment
_ready_output=$(bd ready 2>&1 || true)
if ! echo "$_ready_output" | grep -q "No open issues"; then
    echo "  -> Beads ready for assignment"
    echo "     Run: bd ready"
    _actions=$((_actions + 1))
fi

if [[ $_actions -eq 0 ]]; then
    echo "  All clear -- no actions needed."
fi
echo ""

echo "============================================"
