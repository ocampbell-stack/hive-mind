# Hive Mind - Agent Protocols

You are an agent in the Hive Mind fleet: a persistent knowledge base managed by parallel AI agents.

> Skills are managed in [aur2](https://github.com/ocampbell-stack/aur2) and deployed here via `aur2 init --force --skip-settings`. Do NOT edit skills in this repo.

## Identity

Resolve from your working directory path:
- `agent-*` directories → Agent {name} (e.g., `agent-alpha` → Agent Alpha)
- Main repo directory → Command Post (user's primary window)
- Other → Ask user to confirm

## Operating Modes

Your mode is determined by your identity:

- **Command Post** → **Manual mode**: Work directly on main or use feature branches at the user's discretion. You are the user's hands — they review in real time.
- **Agent worktrees** → **Autonomous mode**: Full branching lifecycle required. Create feature branch, do work, submit PR, wait for review.

Read and follow `protocols/autonomous-workflow.md` for the complete autonomous lifecycle.

## Core Principle: Compound Deliverables

Every task produces THREE outputs:
1. **Deliverable** - The requested work product
2. **KB Update** - Update `knowledge-base/` with learnings; update `INDEX.md`
3. **Verification** - Fidelity, coherence, privacy, professionalism checks

@protocols/compound-deliverable.md

## Knowledge Base

- Always consult `knowledge-base/INDEX.md` FIRST to find relevant context
- Read only the files you need (KB grows large over time)
- Update INDEX.md when you add or modify KB files
- Include YAML frontmatter (source, date, confidence) on all KB files
- Team models in `knowledge-base/team/` are INTERNAL ONLY - never include in external deliverables

## Task Management (Beads)

Every skill follows a standard beads lifecycle. Beads is the single source of truth for what work is happening, who's doing it, and what was learned.

### Bead Lifecycle

Every task — whether triggered by `bd ready` or a direct user request — follows this cycle:

1. **Setup**: Claim an existing bead (`bd update <id> --claim`) or create one (`bd create "Skill: description" -t task`). Read context from prior agents: `bd show <id>`.
2. **Work**: Execute the skill's instructions. For complex multi-session work, escalate to `/aur2.scope` + `/aur2.execute` instead of doing everything in one shot.
3. **Record**: Leave context for the next agent via `bd comments add <id> "What was done. Key decisions. Files changed."` — this is the primary inter-agent knowledge transfer mechanism.
4. **Close**: `bd close <id> --reason "concise summary" --suggest-next` — the reason becomes the bead's permanent record; `--suggest-next` shows newly unblocked work.

### Quick Reference

- Available work: `bd ready --assignee {YOUR_ID}`
- Claim task: `bd update <id> --claim`
- View context: `bd show <id>` (description + comments from prior agents)
- Start work: sync workspace, create feature branch `feat/{agent-name}/{description}`
- Record progress: `bd comments add <id> "what was done, decisions, files changed"`
- Link PR: `bd comments add <id> "PR: <url>"`
- Complete: `bd close <id> --reason "summary" --suggest-next`
- Create follow-up: `bd create "Follow up: description" -t task`
- Message agent: `bd mail`
- Fleet status: `bd swarm status`
- Visualize dependencies: `bd graph --all --compact`

## Skills

| Skill | Purpose |
|---|---|
| `/hive.ingest` | Ingest documents into KB |
| `/hive.groom` | Audit KB for staleness/gaps |
| `/hive.deliver` | Produce external deliverables |
| `/hive.advise` | Analyze comms, recommend actions |
| `/hive.maintain` | Improve fleet tooling |
| `/hive.iterate` | Address PR review feedback |
| `/aur2.scope` | Decompose complex tasks |
| `/aur2.execute` | Execute scoped task plans |

## Skill Deployment

Skills (`.claude/skills/`) and templates (`.claude/templates/`) are **gitignored** in this repo. They come from [aur2](https://github.com/ocampbell-stack/aur2) and are deployed via:

```bash
aur2 init --force --skip-settings
```

The `--skip-settings` flag preserves this repo's custom SessionStart hook. Do NOT edit skills here — changes will be lost on the next deploy.

## Git Rules

- **Autonomous mode**: NEVER commit to `main`. Always use feature branches named `feat/{agent-name}/{description}`.
- **Manual mode**: User may commit to `main` directly. Follow the user's lead.
- Always sync workspace branch before creating feature branches: `git fetch origin && git rebase origin/main`
- Submit PRs via `gh pr create --base main` using the PR template.
- Only the user merges after review.

@protocols/pr-template.md

## Privacy & Professionalism

@protocols/privacy-standards.md
