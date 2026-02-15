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

3. **Create PR** targeting `main` using the format below:
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
```

## PR Feedback Iteration

When iterating on review comments (typically via `/hive.iterate`):

1. **Identify the PR** — from input, or detect from current branch:
   ```bash
   gh pr list --head $(git branch --show-current) --json number,url
   ```

2. **Ensure correct branch** — check out the feature branch if needed.

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
   gh pr comment <number> --body "Addressed feedback: <bullet list>"
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

After a PR merges:
```bash
git checkout {agent-name}/workspace
git branch -d feat/{agent-name}/{task-description}
git fetch origin
git rebase origin/main
```

Or run `scripts/cleanup.sh` from Command Post to batch-clean all merged branches.
