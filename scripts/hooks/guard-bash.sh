#!/usr/bin/env bash
# guard-bash.sh — PreToolUse guardrail for Bash commands
#
# Prevents dangerous git operations in the hive-mind workflow:
#   1. git push template — would leak private content to public repo
#   2. git commit on main in agent worktrees — enforces feature branch workflow
#
# Receives hook input JSON on stdin. Returns permissionDecision JSON on stdout.
# Exits 0 always — a broken guardrail should never block legitimate work.

set -uo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null) || exit 0

# --- Guard 1: Block "git push template" ---
# The "template" remote points to the public hive-mind repo.
# Pushing to it from a private instance would leak private content.
if echo "$COMMAND" | grep -qE 'git\s+push\s+(-\S+\s+)*template(\s|$)'; then
  cat <<'EOF'
{"permissionDecision":"deny","reason":"BLOCKED: `git push template` would push private content to the public template repo. Use `git push` (no args) to push to origin."}
EOF
  exit 0
fi

# --- Guard 2: Block git commit on main in agent worktrees ---
# Agents must use feature branches (feat/{agent-name}/...) and submit PRs.
if echo "$COMMAND" | grep -qE 'git\s+commit'; then
  if echo "${CLAUDE_PROJECT_DIR:-}" | grep -qE '/agent-[^/]+$'; then
    BRANCH=$(cd "$CLAUDE_PROJECT_DIR" && git branch --show-current 2>/dev/null) || true
    if [ "$BRANCH" = "main" ]; then
      cat <<'EOF'
{"permissionDecision":"deny","reason":"BLOCKED: Agents must not commit directly to main. Create a feature branch first: `git checkout -b feat/{agent-name}/{description}`"}
EOF
      exit 0
    fi
  fi
fi

# No objection
exit 0
