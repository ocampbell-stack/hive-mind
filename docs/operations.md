# Operations Guide

Day-to-day fleet management for your Hive Mind instance. This covers what happens *after* setup — how to monitor agents, triage work, and keep the system running.

## Fleet Status

### Quick Check

```bash
# From Command Post (your main hive-mind directory)
./scripts/dashboard.sh
```

The dashboard shows worktrees, branches, open/ready tasks, KB stats, recent commits, and open PRs in one view.

### Detailed Status

```bash
bd status              # Project overview: open/closed/blocked counts
bd list --status open  # All open beads
bd ready               # Beads with no blockers — available for work
bd blocked             # Beads waiting on dependencies
bd stale               # Beads not updated recently
bd graph --all --compact  # Visual dependency graph
```

### Agent Activity

```bash
bd list --status in_progress              # What's being worked on right now
bd list --assignee alpha                  # Everything assigned to agent-alpha
gh pr list                                # Open PRs awaiting review
git log --oneline --all -10               # Recent commits across all branches
```

## Assigning Work

### Option A: Direct Skill Invocation

Open a session in any agent worktree and invoke a skill directly. The skill creates its own bead automatically.

```bash
cd agent-alpha
claude
> /hive.ingest the attached Q1 planning doc
```

The agent will: create a bead, gather relevant KB context, confirm its approach with you (for ambiguous or high-impact tasks), do the work, commit, push, create a PR.

### Option B: Pre-Create a Bead, Then Launch an Agent

Create the bead from Command Post, assign it, then start the agent:

```bash
# From Command Post
bd create "Ingest February design review notes" -t task -a alpha

# Then start the agent
cd ../agent-alpha
claude
> Check bd ready and work on your assigned bead
```

The agent will find the pre-assigned bead via `bd ready --assignee alpha` or `bd list --assignee alpha`.

### Option C: Let Agents Self-Serve from the Backlog

If there are unassigned beads in the ready queue (from prior grooming, scope execution, or follow-up work):

```bash
cd agent-alpha
claude
> Check bd ready and pick up the next available task
```

The agent claims a bead via `bd update <id> --claim` (atomic — prevents two agents from grabbing the same bead).

## Triaging the Beads Backlog

Work generates more work. `/hive.groom` creates remediation beads, `/hive.advise` creates action items, and `/aur2.execute` creates dependency graphs. Over time, the backlog grows. Here's how to manage it.

### View the Backlog

```bash
bd ready                   # What's available right now
bd list --status open      # Everything open (including blocked)
bd blocked                 # What's stuck on dependencies
```

### Prioritize

Beads support priority levels 0-4 (0 = critical, 4 = backlog):

```bash
bd update <id> --priority 1    # Escalate
bd update <id> --priority 4    # Deprioritize
```

### Defer

Push non-urgent beads out of the ready queue:

```bash
bd update <id> --defer "+2w"       # Hide for 2 weeks
bd update <id> --defer "2025-04-01"  # Hide until a specific date
bd list --status deferred            # See what's deferred
```

### Close Without Working

If a bead is no longer relevant:

```bash
bd close <id> --reason "No longer needed — superseded by <id>"
```

## Monitoring Multi-Bead Projects

When `/aur2.execute` implements a scope, an **epic** bead is created as a parent container for all the scope's tasks. This gives you a single ID to track progress. (The scope itself is produced by `/aur2.scope` and submitted as a PR for your review before execution begins.)

### Checking Scope Progress

```bash
bd epic status                   # Summary of all epics (completed/total per epic)
bd swarm status <epic-id>        # Detailed breakdown: completed, active, ready, blocked
bd ready --parent <epic-id>      # What's available in this specific scope
bd graph --all --compact         # Full dependency DAG across all scopes
```

The dashboard (`./scripts/dashboard.sh`) includes an "EPIC PROGRESS" section that shows this automatically.

### During Execution

The agent works through beads sequentially on a single feature branch. You can check in from Command Post at any time:

```bash
bd swarm status <epic-id>    # How far along is this scope?
bd list --status in_progress   # What's the agent working on right now?
```

### After Partial Completion

If a session ends before all beads are done (e.g., context limit), the remaining beads stay in the ready queue under the epic. Start a new session in the same worktree and the agent picks up where it left off:

```bash
cd agent-alpha
claude
> Continue working through bd ready --parent <epic-id>
```

### One Scope = One Agent = One PR

Each scope execution runs on a single feature branch and produces a single PR. Multi-agent parallelism happens at the scope level — assign different scopes to different agents, not different beads within the same scope.

## Handling Follow-Up Beads

Several skills create follow-up beads during execution:

| Skill | Follow-up beads created |
|---|---|
| `/hive.groom` | Remediation beads: stale entries to update, contradictions to resolve, gaps to fill |
| `/hive.advise` | Action item beads: tasks from communication analysis |
| `/hive.ingest` | Verification beads: confirm ingested content (when warranted) |
| `/aur2.execute` | Remaining scope beads that weren't completed in the session |

Follow-up beads are surfaced in two places:
1. **`bd close --suggest-next` output** — shown to the agent at the end of the skill
2. **PR description** — listed in the "Follow-up Work" section

To process follow-up beads:
```bash
bd ready              # See what's available
bd show <id>          # Read the context the creating agent left behind
# Then assign to an agent (Option A, B, or C above)
```

## PR Review Workflow

Agents seek alignment with you **before** implementation (via `AskUserQuestion` for ambiguous or high-impact work). This means most issues should be caught early. The PR review is a second checkpoint for verifying the finished product.

1. Agent completes work and creates a PR via `gh pr create`
2. You receive the PR on GitHub
3. Review the deliverable AND the KB changes
4. Leave comments on anything that needs revision
5. Agent addresses feedback via `/hive.iterate #<PR-number>`
6. Repeat until satisfied, then merge

```bash
# From Command Post — see all open PRs
gh pr list

# After merging, clean up
./scripts/cleanup.sh        # Prune merged branches
```

## Common Operations

### Checking KB Health

```bash
# Quick: run from any session
cd agent-alpha && claude
> /hive.groom the strategic-context section

# Full audit
> /hive.groom
```

### Processing Queued Visions

```bash
# Drop a text vision
echo "Prepare board deck for Q2 priorities" > .aur2/visions/queue/q2-board-deck.txt

# Or record audio (requires OpenAI API key)
source .aur2/.venv/bin/activate
python .aur2/scripts/record_memo.py

# Then process from any session
> /aur2.process_visions
```

### Planning Complex Work

```bash
# Step 1: Produce the scope (agent submits as PR in autonomous mode)
> /aur2.scope "Restructure KB to add competitive analysis section"
# → Creates .aur2/plans/queue/<name>/scope.md
# → In autonomous mode: submits scope as PR for your review

# Step 2: Review the scope PR on GitHub
# → Leave comments if changes needed → agent iterates via /hive.iterate
# → Approve when satisfied

# Step 3: Execute the approved scope (separate session/invocation)
> /aur2.execute .aur2/plans/queue/<name>/scope.md
```

### Cleaning Up

```bash
# From Command Post
./scripts/cleanup.sh          # Prune merged branches and stale worktrees
./scripts/cleanup.sh --dry-run  # Preview what would be cleaned
```
