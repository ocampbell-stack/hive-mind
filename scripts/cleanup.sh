#!/usr/bin/env bash
# cleanup.sh - Post-merge cleanup for Hive Mind agent worktrees
#
# Usage:
#   ./scripts/cleanup.sh <agent-name>    Clean up a specific agent (e.g., "alpha")
#   ./scripts/cleanup.sh --all           Clean up all agent worktrees
#   ./scripts/cleanup.sh --dry-run alpha Preview what would happen
#
# What it does:
#   1. Fetches origin
#   2. Fast-forwards local main to origin/main
#   3. Switches the agent worktree back to its workspace branch
#   4. Rebases the workspace branch onto updated main
#   5. Deletes merged local feature branches for the agent
#   6. Prunes remote tracking refs for deleted remote branches
#
# Designed to run from Command Post (hive-mind-private root) after merging
# a PR via the GitHub web UI.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_DIR="$(cd "$REPO_DIR/.." && pwd)"
DRY_RUN=false
ALL_AGENTS=false
AGENTS=()

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --all)
            ALL_AGENTS=true
            shift
            ;;
        -h|--help)
            head -16 "$0" | tail -14
            exit 0
            ;;
        *)
            AGENTS+=("$1")
            shift
            ;;
    esac
done

# Discover agents from worktrees if --all
if $ALL_AGENTS; then
    while IFS= read -r line; do
        dir=$(echo "$line" | awk '{print $1}')
        name=$(basename "$dir")
        if [[ "$name" == agent-* ]]; then
            AGENTS+=("${name#agent-}")
        fi
    done < <(git -C "$REPO_DIR" worktree list)
fi

if [[ ${#AGENTS[@]} -eq 0 ]]; then
    echo "Usage: ./scripts/cleanup.sh <agent-name> | --all [--dry-run]"
    echo "  e.g. ./scripts/cleanup.sh alpha"
    echo "  e.g. ./scripts/cleanup.sh --all --dry-run"
    exit 1
fi

if $DRY_RUN; then
    echo "=== DRY RUN ==="
    echo ""
fi

echo "=== Post-Merge Cleanup ==="
echo "Repo: $REPO_DIR"
echo "Agents: ${AGENTS[*]}"
echo ""

# --- Step 1: Fetch origin ---
echo "--- Fetching origin ---"
if $DRY_RUN; then
    echo "  Would run: git fetch origin --prune"
else
    git -C "$REPO_DIR" fetch origin --prune
    echo "  Done."
fi
echo ""

# --- Step 2: Fast-forward local main ---
echo "--- Updating local main ---"
CURRENT_BRANCH=$(git -C "$REPO_DIR" branch --show-current)
if [[ "$CURRENT_BRANCH" == "main" ]]; then
    if $DRY_RUN; then
        LOCAL=$(git -C "$REPO_DIR" rev-parse main)
        REMOTE=$(git -C "$REPO_DIR" rev-parse origin/main 2>/dev/null || echo "unknown")
        echo "  Local main:  ${LOCAL:0:7}"
        echo "  Remote main: ${REMOTE:0:7}"
        echo "  Would run: git pull --ff-only"
    else
        git -C "$REPO_DIR" pull --ff-only
        echo "  Main is up to date."
    fi
else
    echo "  Command Post not on main (on $CURRENT_BRANCH), updating main ref directly..."
    if $DRY_RUN; then
        echo "  Would run: git fetch origin main:main"
    else
        git -C "$REPO_DIR" fetch origin main:main
        echo "  Done."
    fi
fi
echo ""

# --- Per-agent cleanup ---
for agent in "${AGENTS[@]}"; do
    WORKTREE="$WORKSPACE_DIR/agent-$agent"
    WORKSPACE_BRANCH="agent-$agent/workspace"

    echo "=== Agent: $agent ==="

    if [[ ! -d "$WORKTREE" ]]; then
        echo "  WARNING: Worktree not found at $WORKTREE, skipping."
        echo ""
        continue
    fi

    # Step 3: Switch worktree to workspace branch
    WORKTREE_BRANCH=$(git -C "$WORKTREE" branch --show-current)
    if [[ "$WORKTREE_BRANCH" != "$WORKSPACE_BRANCH" ]]; then
        echo "  Switching from $WORKTREE_BRANCH → $WORKSPACE_BRANCH"
        if $DRY_RUN; then
            echo "  Would run: git -C $WORKTREE checkout $WORKSPACE_BRANCH"
        else
            git -C "$WORKTREE" checkout "$WORKSPACE_BRANCH"
        fi
    else
        echo "  Already on $WORKSPACE_BRANCH"
    fi

    # Step 4: Rebase workspace onto updated main
    echo "  Rebasing $WORKSPACE_BRANCH onto main..."
    if $DRY_RUN; then
        LOCAL_WS=$(git -C "$REPO_DIR" rev-parse "$WORKSPACE_BRANCH" 2>/dev/null || echo "unknown")
        LOCAL_MAIN=$(git -C "$REPO_DIR" rev-parse main 2>/dev/null || echo "unknown")
        echo "  $WORKSPACE_BRANCH: ${LOCAL_WS:0:7}"
        echo "  main:              ${LOCAL_MAIN:0:7}"
        if [[ "$LOCAL_WS" == "$LOCAL_MAIN" ]]; then
            echo "  Already up to date."
        else
            echo "  Would run: git -C $WORKTREE rebase main"
        fi
    else
        git -C "$WORKTREE" rebase main
        echo "  Done."
    fi

    # Step 5: Delete merged local feature branches
    MERGED=$(git -C "$REPO_DIR" branch --merged main 2>/dev/null \
        | grep -v '^\*' \
        | grep "feat/agent-$agent" \
        | xargs \
        || true)

    if [[ -n "$MERGED" ]]; then
        echo "  Deleting merged feature branches:"
        for branch in $MERGED; do
            if $DRY_RUN; then
                echo "    Would delete: $branch"
            else
                git -C "$REPO_DIR" branch -d "$branch"
                echo "    Deleted: $branch"
            fi
        done
    else
        echo "  No merged feature branches to clean up."
    fi

    echo ""
done

# --- Summary ---
echo "=== Summary ==="
echo "Worktrees:"
git -C "$REPO_DIR" worktree list
echo ""
echo "Local branches:"
git -C "$REPO_DIR" branch
echo ""
echo "Remote branches:"
git -C "$REPO_DIR" branch -r
echo ""
echo "Cleanup complete."
