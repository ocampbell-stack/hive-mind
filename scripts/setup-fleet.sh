#!/usr/bin/env bash
# setup-fleet.sh - Create agent worktrees for the Hive Mind fleet
# Usage: ./scripts/setup-fleet.sh [agent-name...]
# Example: ./scripts/setup-fleet.sh alpha beta gamma

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_DIR="$(cd "$REPO_DIR/.." && pwd)"

# Default agents if none specified
AGENTS=("${@:-alpha beta}")

echo "=== Hive Mind Fleet Setup ==="
echo "Repo: $REPO_DIR"
echo "Workspace: $WORKSPACE_DIR"
echo ""

# Verify prerequisites
echo "Checking prerequisites..."

if ! command -v bd &>/dev/null; then
    echo "ERROR: beads (bd) not installed. Run: brew tap steveyegge/beads && brew install beads"
    exit 1
fi

if ! command -v gh &>/dev/null; then
    echo "ERROR: GitHub CLI (gh) not installed. Run: brew install gh"
    exit 1
fi

if ! gh auth status &>/dev/null; then
    echo "ERROR: Not authenticated with GitHub. Run: gh auth login"
    exit 1
fi

if ! git -C "$REPO_DIR" rev-parse --git-dir &>/dev/null; then
    echo "ERROR: $REPO_DIR is not a git repository"
    exit 1
fi

# Ensure we have at least one commit (worktrees need a commit)
if ! git -C "$REPO_DIR" rev-parse HEAD &>/dev/null; then
    echo "ERROR: No commits yet. Make an initial commit first."
    exit 1
fi

echo "All prerequisites OK."
echo ""

# Set default GitHub repo (needed when multiple remotes exist)
REPO_URL=$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null || true)
if [[ "$REPO_URL" =~ github\.com[:/](.+/.+?)(\.git)?$ ]]; then
    GH_REPO="${BASH_REMATCH[1]}"
    echo "Setting default GitHub repo: $GH_REPO"
    gh repo set-default "$GH_REPO"
else
    echo "WARNING: Could not detect GitHub repo from origin remote. Run 'gh repo set-default' manually."
fi
echo ""

# Create worktrees for each agent
for agent in "${AGENTS[@]}"; do
    WORKTREE_PATH="$WORKSPACE_DIR/agent-$agent"
    BRANCH_NAME="agent-$agent/workspace"

    if [ -d "$WORKTREE_PATH" ]; then
        echo "SKIP: agent-$agent worktree already exists at $WORKTREE_PATH"
        continue
    fi

    echo "Creating worktree for agent-$agent..."
    git -C "$REPO_DIR" worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME"
    echo "  Created: $WORKTREE_PATH (branch: $BRANCH_NAME)"
done

echo ""
echo "=== Fleet Status ==="
git -C "$REPO_DIR" worktree list
echo ""
echo "Fleet setup complete. Start agents with:"
for agent in "${AGENTS[@]}"; do
    echo "  cd $WORKSPACE_DIR/agent-$agent && claude"
done
