# Workflow Protocol

How work moves from task to shipped PR. Covers mode detection, branching, PR creation, and feedback iteration.

## Mode Detection

Determine your operating mode from the working directory path:

- `agent-*` directory → **Autonomous mode** (this protocol's full lifecycle applies)
- Main repo directory → **Manual mode** (skip branching; follow the user's lead)

## Autonomous Mode — Full Lifecycle

### Before Work

1. **Sync workspace** with main:
   ```bash
   git fetch origin
   git rebase origin/main
   ```

2. **Check for existing feature branch** (if resuming):
   ```bash
   git branch --show-current
   ```
   If already on a `feat/` branch, skip creation. Check for existing PR:
   ```bash
   gh pr list --head $(git branch --show-current) --json number,url
   ```

3. **Create feature branch** (if not resuming):
   ```bash
   git checkout -b feat/{agent-name}/{task-description}
   ```

4. **Track in beads**: Claim or create a bead (see skill-lifecycle.md for details).

### Doing the Work

Follow the invoked skill's instructions. The skill lifecycle handles alignment, execution, and verification.

### After Work

1. **Stage and commit**:
   ```bash
   git add -A
   git commit -m "<descriptive message>"
   ```
   Multiple commits are fine for larger tasks — commit logical units of work.

2. **Sync and push**:
   ```bash
   bd sync
   gh auth setup-git
   git push -u origin feat/{agent-name}/{task-description}
   ```

3. **Create PR** targeting `main` using the format below:
   ```bash
   gh pr create --base main --title "<title>" --body "<body>"
   ```

4. **Record PR in bead**:
   ```bash
   bd comments add <id> "PR: <pr-url>"
   ```

5. **Report to user**: Output the PR URL and a summary of what was done.

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
