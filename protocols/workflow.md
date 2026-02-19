# Workflow Protocol

How work moves from task to shipped PR. Covers mode detection, the skill lifecycle, branching, PR creation, and feedback iteration.

## Mode Detection

Determine your operating mode from the working directory path:

- `agent-*` directory → **Autonomous mode** (full lifecycle applies)
- Main repo directory → **Manual mode** (skip branching; follow the user's lead)

## Skill Lifecycle

Every skill follows this lifecycle. Skills reference this protocol for setup and closeout, then provide their own instructions for the core work phase (step 6).

### 1. Sync Workspace (autonomous only)

```bash
git fetch origin
git rebase origin/main
```

If already on a `feat/` branch (resuming), skip branch creation. Check for existing PR:
```bash
gh pr list --head $(git branch --show-current) --json number,url
```

If picking up work on an existing PR (via resume, `/hive.iterate`, or user instruction):
1. Resolve the target branch from the PR:
   ```bash
   PR_BRANCH=$(gh pr view <number> --json headRefName -q .headRefName)
   ```
2. If not already on that branch, check it out:
   ```bash
   git fetch origin
   git checkout "$PR_BRANCH"
   ```
3. If checkout fails because the branch is checked out in another worktree, tell the user:
   > Branch `{branch}` is currently checked out in another worktree. Run `./scripts/cleanup.sh {agent}` from the Command Post to free it, then retry.

### 2. Beads Setup

- If triggered by an existing bead: `bd update <id> --claim` (or `--status in_progress` if already yours)
- If triggered by user request with no bead: `bd create "<Skill prefix>: <description>" -t task`
- Read prior context: `bd show <id>` for description and comments from prior agents

### 3. Complexity Check

- If the work will require more than one session, escalate to `/aur2.scope` to produce a scope PR for user review
- Close the current bead with a note: `bd comments add <id> "Escalated to /aur2.scope. Scope PR: pending"`
- Then close: `bd close <id> --reason "Escalated to scope" --suggest-next`
- `/aur2.execute` runs separately after the user approves the scope
- For single-session work, proceed directly

### 4. Preliminary Alignment

Follow `protocols/alignment.md`:
- Read `knowledge-base/INDEX.md` and relevant KB files
- Assess impact — what will change, any overlaps or contradictions
- Confirm approach with user (pause for ambiguous/high-impact, proceed for clear/scoped)

### 5. Create Feature Branch (autonomous only)

```bash
git checkout -b feat/{agent-name}/{task-description}
```

### 6. [Skill-Specific Work]

Follow the invoked skill's instructions.

### 7. Verify

Follow `protocols/quality.md`:
- Determine task weight (full or light)
- Run the appropriate verification checks
- Fix any failures before proceeding
- If external sources were processed, enumerate external links found in the content. Attempt to follow links whose content would be useful for the task (use judgment — skip obviously irrelevant or inaccessible links). Report all link outcomes in the Source Accessibility section of the PR.

### 8. Commit, Push, and PR (autonomous only)

1. **Stage and commit**:
   ```bash
   git add -A
   git commit -m "<descriptive message>"
   ```
   Multiple commits are fine for larger tasks — commit logical units of work.

2. **Push**:
   ```bash
   gh auth setup-git
   git push -u origin feat/{agent-name}/{task-description}
   ```

3. **Capture session and context** (for resumability):
   ```bash
   # Claude Code stores session transcripts as ~/.claude/projects/<encoded-path>/<uuid>.jsonl
   # where <encoded-path> is $PWD with slashes replaced by dashes (e.g. /Users/me/repo → -Users-me-repo).
   # This grabs the UUID from the most recently modified .jsonl file, which is the active session.
   # Uses /bin/ls to avoid shell aliases (e.g. eza). Fails gracefully to empty string if no sessions exist.
   CLAUDE_SESSION=$(/bin/ls -1t ~/.claude/projects/$(echo "$PWD" | tr '/' '-')/*.jsonl 2>/dev/null | head -1 | sed 's/.*\///' | sed 's/\.jsonl$//')
   AGENT_NAME=$(basename "$PWD" | sed 's/^agent-//')
   CURRENT_BRANCH=$(git branch --show-current)
   ```

4. **Create PR** targeting `main` using the format below (include `$CLAUDE_SESSION` in the Session section):
   ```bash
   gh pr create --base main --title "<title>" --body "<body>"
   ```

### 9. Record and Close

- Record context for the next agent:
  ```bash
  bd comments add <id> "What was done. Key decisions. Files changed. PR: {url or N/A}"
  ```
- Close the bead:
  ```bash
  bd close <id> --reason "concise summary" --suggest-next
  ```
- Review `--suggest-next` output for newly unblocked work
- **Report to user**: Output the PR URL and a summary of what was done.

## PR Format

```
## Summary
Brief description of what this PR accomplishes.

## Source Accessibility
_Include only when the task processed external documents, URLs, or non-markdown input. Omit for internal KB work or code-only changes._

- **Processed**: What was successfully read and extracted
- **Links followed**: URLs in the source material that were fetched and read (list each)
- **Links not followed**: URLs that were skipped or couldn't be accessed, with reason per link (not relevant to task, auth-gated, no MCP tool available, etc.)
- **Inaccessible**: Other content that could not be read (embedded images, binary data, etc.)
- **Format issues**: Inefficiencies in the source format (e.g., base64-encoded images inflating file size, HTML artifacts)
- **Recommendations**: How the user can improve input for future invocations

## Deliverable
- What was produced and why

## KB Changes
- Files added/modified in knowledge-base/
- INDEX.md updated: yes/no

## Verification
- [ ] Fidelity: Matches task requirements
- [ ] Coherence: Consistent with existing KB
- [ ] Privacy: No internal models or sensitive info exposed
- [ ] Professionalism: Appropriate for external review

## Beads Task
- Task ID: `<bead-id>`
- Status: Closed with reason

## Follow-up Work
- Beads created: `<bead-id>: <title>` (or "None")

## Notes
Any additional context for the reviewer.

## Session
- Agent: `$AGENT_NAME`
- Branch: `$CURRENT_BRANCH`
- Hash: `<session-id>`
- Resume: `cd <agent-worktree-path> && claude --resume <session-id>`
```

## PR Feedback Iteration

When iterating on review comments (typically via `/hive.iterate`):

1. **Identify the PR** — from input (PR number or URL). If not provided, attempt detection from current branch:
   ```bash
   gh pr list --head $(git branch --show-current) --json number,url
   ```

2. **Check out the PR's branch**:
   ```bash
   PR_BRANCH=$(gh pr view <number> --json headRefName -q .headRefName)
   CURRENT=$(git branch --show-current)
   if [ "$CURRENT" != "$PR_BRANCH" ]; then
     git fetch origin
     git checkout "$PR_BRANCH"
   fi
   ```
   If checkout fails because the branch is checked out in another worktree, tell the user to run `./scripts/cleanup.sh {agent}` from the Command Post to free it.

3. **Read feedback**:
   ```bash
   gh pr view <number> --comments
   gh api repos/{owner}/{repo}/pulls/<number>/reviews
   ```

4. **Address each unresolved comment** — make the change, update INDEX.md if KB content changed.

5. **Commit, push, and notify**:
   ```bash
   git add -A
   git commit -m "address review: <summary>"
   git push
   # Session and context capture — see Step 8.3 above for how this works
   CLAUDE_SESSION=$(/bin/ls -1t ~/.claude/projects/$(echo "$PWD" | tr '/' '-')/*.jsonl 2>/dev/null | head -1 | sed 's/.*\///' | sed 's/\.jsonl$//')
   AGENT_NAME=$(basename "$PWD" | sed 's/^agent-//')
   gh pr comment <number> --body "Addressed feedback: <bullet list>

   ---
   Agent: \`$AGENT_NAME\` · Session: \`$CLAUDE_SESSION\` · Resume: \`cd $PWD && claude --resume $CLAUDE_SESSION\`"
   ```

6. **Update beads**: `bd comments add <id> "Review feedback addressed (round N)"`

7. **Report** — summarize changes made and any comments needing clarification.

## Manual Mode

- Skip branching unless the user requests a feature branch
- The user may commit directly to main — follow their lead
- The skill lifecycle still applies — just skip the autonomous-only steps (1, 5, 8)
- Beads tracking still applies (skills create/claim beads in all modes)
- Quality checks still apply (@protocols/quality.md)

## Post-Merge Cleanup

After merging a PR via the GitHub web UI, run from Command Post:

```bash
# Single agent
./scripts/cleanup.sh alpha

# All agents at once
./scripts/cleanup.sh --all

# Preview first
./scripts/cleanup.sh --dry-run alpha
```

This fetches origin, fast-forwards local main, switches the worktree back to its workspace branch, rebases onto main, and deletes merged feature branches. Remote feature branches are auto-deleted by GitHub on merge.
