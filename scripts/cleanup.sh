#!/usr/bin/env bash
# cleanup.sh - Post-merge cleanup: prune worktrees and merged branches
# Usage: ./scripts/cleanup.sh [--dry-run]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DRY_RUN=false

if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "=== DRY RUN MODE ==="
    echo ""
fi

echo "=== Hive Mind Cleanup ==="
echo "Repo: $REPO_DIR"
echo ""

# Prune worktrees that point to missing directories
echo "--- Pruning stale worktrees ---"
if $DRY_RUN; then
    git -C "$REPO_DIR" worktree list | while read -r line; do
        dir=$(echo "$line" | awk '{print $1}')
        if [ ! -d "$dir" ]; then
            echo "  Would prune: $line"
        fi
    done
else
    git -C "$REPO_DIR" worktree prune -v 2>&1 || echo "  Nothing to prune"
fi
echo ""

# List merged feature branches (candidates for deletion)
echo "--- Merged feature branches ---"
MERGED_BRANCHES=$(git -C "$REPO_DIR" branch --merged main 2>/dev/null | grep -v '^\*' | grep -v 'main' | grep 'feat/' || true)

if [ -z "$MERGED_BRANCHES" ]; then
    echo "  No merged feature branches found"
else
    echo "$MERGED_BRANCHES" | while read -r branch; do
        branch=$(echo "$branch" | xargs)  # trim whitespace
        if $DRY_RUN; then
            echo "  Would delete: $branch"
        else
            echo "  Deleting: $branch"
            git -C "$REPO_DIR" branch -d "$branch"
        fi
    done
fi
echo ""

# Show remaining worktrees
echo "--- Current worktrees ---"
git -C "$REPO_DIR" worktree list
echo ""

# Show remaining branches
echo "--- Remaining branches ---"
git -C "$REPO_DIR" branch -a
echo ""

echo "Cleanup complete."
