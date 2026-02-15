# Skill Lifecycle Protocol

Standard lifecycle that all `hive.*` skills follow. Each skill references this protocol for setup and closeout, then provides its own unique instructions for the core work.

## Before Work

### 1. Determine Operating Mode
Read `protocols/workflow.md` for mode detection. If autonomous, follow the full branching lifecycle (sync, branch, work, commit, PR).

### 2. Beads Setup
- If triggered by an existing bead: `bd update <id> --claim` (or `--status in_progress` if already yours)
- If triggered by user request with no bead: `bd create "<Skill prefix>: <description>" -t task`
- Read prior context: `bd show <id>` for description and comments from prior agents

### 3. Complexity Check
- If the work will require more than one session, escalate to `/aur2.scope` to produce a scope PR for user review
- Close the current bead with a note pointing to the scope: `bd comments add <id> "Escalated to /aur2.scope. Scope PR: pending"`
- Then close: `bd close <id> --reason "Escalated to scope" --suggest-next`
- `/aur2.execute` runs separately after the user approves the scope
- For single-session work, proceed directly

### 4. Preliminary Alignment
Follow `protocols/alignment.md`:
- Read `knowledge-base/INDEX.md` and relevant KB files
- Assess impact — what will change, any overlaps or contradictions
- Confirm approach with user (pause for ambiguous/high-impact, proceed for clear/scoped)

## [Skill-Specific Work]

The invoking skill's unique instructions go here.

## After Work

### 5. Verify
Follow `protocols/quality.md`:
- Determine task weight (full or light)
- Run the appropriate verification checks
- Fix any failures before proceeding

### 6. Close and Hand Off
- If autonomous, follow `protocols/workflow.md` for commit, push, and PR creation
- Record context for the next agent:
  ```bash
  bd comments add <id> "What was done. Key decisions. Files changed. PR: {url or N/A}"
  ```
- Close the bead:
  ```bash
  bd close <id> --reason "concise summary" --suggest-next
  ```
- Review `--suggest-next` output for newly unblocked work
