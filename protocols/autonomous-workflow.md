# Autonomous Workflow Protocol

This protocol governs how agents work on feature branches in agent worktrees. It is the standard workflow for all skill-based tasks assigned to agents.

## Mode Detection

Determine your operating mode from the working directory:

- Path contains `agent-alpha`, `agent-beta`, or similar `agent-*` pattern → **Autonomous mode** (this protocol applies)
- Path contains the main repo directory (e.g. `hive-mind-main`) → **Manual mode** (skip this protocol; follow user's lead)

## Autonomous Mode — Full Lifecycle

### Before Starting Work

1. **Sync workspace branch** with main:
   ```bash
   git fetch origin
   git rebase origin/main
   ```

2. **Check for existing feature branch** — if you're resuming a session:
   ```bash
   git branch --show-current
   ```
   If already on a `feat/` branch, skip branch creation. Check if a PR exists:
   ```bash
   gh pr list --head $(git branch --show-current) --json number,url
   ```

3. **Create feature branch** (if not resuming):
   ```bash
   git checkout -b feat/{agent-name}/{task-description}
   ```
   Example: `feat/alpha/ingest-feb12-design-review`

4. **Track in beads**:
   - If a bead was pre-assigned: `bd update <id> --claim`
   - If no bead exists: `bd create --title "<task>" --description "<details>"`
   - Mark in progress: `bd update <id> --status in_progress`

### Doing the Work

Execute the invoked skill's instructions. The compound deliverable protocol always applies:
1. Produce the requested deliverable
2. Update `knowledge-base/` with learnings; update `INDEX.md`
3. Run verification checks (fidelity, coherence, privacy, professionalism)

### After Completing Work

1. **Stage and commit** all changes:
   ```bash
   git add -A
   git commit -m "<descriptive message>"
   ```
   Multiple commits are fine for larger tasks — commit logical units of work.

2. **Push** to remote:
   ```bash
   gh auth setup-git
   git push -u origin feat/{agent-name}/{task-description}
   ```

3. **Create PR** targeting `main`:
   ```bash
   gh pr create --base main --title "<title>" --body "<body per pr-template.md>"
   ```
   Use the format from `protocols/pr-template.md`.

4. **Record PR in bead**:
   ```bash
   bd comments add <id> "PR: <pr-url>"
   ```

5. **Report to user**: Output the PR URL and a summary of what was done.

## Manual Mode

When operating as Command Post (the user's primary window):
- Skip branching steps unless the user explicitly requests a feature branch
- The user may commit directly to main — follow their lead
- Beads tracking is optional — use it if the user wants visibility
- Compound deliverable protocol still applies (always update KB)

## Post-Merge Cleanup

After the user merges a PR on GitHub:
```bash
git checkout {agent-name}/workspace
git branch -d feat/{agent-name}/{task-description}
git fetch origin
git rebase origin/main
```

Or run `scripts/cleanup.sh` from Command Post to batch-clean all merged feature branches.
