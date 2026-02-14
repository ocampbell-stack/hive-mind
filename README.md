# Hive Mind

A persistent, version-controlled knowledge base managed by parallel AI agents. The Hive Mind treats the user's mental model of their work as a living repository — strategic context, project state, team dynamics, and work products — maintained and extended by a fleet of Claude Code agents operating through git worktrees.

> **This is a private repository.** It may contain models of team members and sensitive strategic context. See [Privacy & Professionalism](#privacy--professionalism) below.

## The Vision

### The Problem

Significant engineering and leadership time is lost to context fragmentation. Every new AI session starts from scratch. Work products, strategic decisions, project state, and relationship context exist only in ephemeral chat sessions or scattered documents. Each new task requires manually re-curating context, cycling through repetitive explanations, and hoping nothing important was lost between sessions.

### The Solution: A Persistent Mental Model

The Hive Mind transitions from ephemeral AI sessions to a **persistent, version-controlled representation of the user's working context**. Rather than treating AI interactions as disposable conversations, the Hive Mind encodes everything an agent needs to be useful — the user's role, their projects, their team, their priorities, their in-progress work — as markdown files in a git repository.

This repository is the shared memory that all agents read from and write to. When one agent learns something, that knowledge is committed to the repo so the next agent can pick up where the last one left off.

### The Compound Deliverable Principle

Every task assigned to an agent has two required outputs:

1. **The External Deliverable** — The actual work product requested: code, a document, an analysis, a recommendation.
2. **The Internal Context Update** — A distinct update to the Hive Mind knowledge base reflecting what the agent learned or what changed.

The rationale: we must assume the *next* agent will need to know what this agent just learned. By encoding this "mental model update" into the repo with every task, we eliminate the need to manually re-paste context for future work. The knowledge base compounds over time — each task leaves the system smarter than it found it.

A third component, **Verification**, ensures that deliverables are faithful to the assignment, consistent with existing knowledge, and compliant with privacy standards. See [`protocols/`](protocols/) for the full verification framework.

### The 5 Agent Workflows

Agents in this fleet execute one of five specific workflows, each backed by a dedicated Claude Code skill:

| Workflow | Skill | Description |
|---|---|---|
| **Ingest Context** | `/hive.ingest` | Incorporate new reference documents, meeting notes, or user observations into the knowledge base. Tag information with source, date, and confidence level for staleness tracking. |
| **Groom the Mental Model** | `/hive.groom` | Proactively audit the knowledge base for stale information, contradictions between entries, and gaps where referenced topics lack documentation. Surface questions for the user to resolve ambiguities. |
| **Produce Deliverables** | `/hive.deliver` | Generate stakeholder-facing outputs — documents, code, plans, analyses — grounded in the current state of the knowledge base. Every claim traceable to a KB source. |
| **Recommend Engagement** | `/hive.advise` | Analyze meeting minutes, chat threads, or communications and recommend specific actions: feedback to give, questions to ask, risks to flag. Informed by team models and project context but never exposing internal assessments. |
| **Maintain the Fleet** | `/hive.maintain` | Improve the Hive Mind's own tooling, scripts, skills, and infrastructure. The system maintains itself. |

For code-centric work, agents also have access to `/aura.scope` (task decomposition) and `/aura.execute` (implementation via dependency-mapped subtasks).

### Human-in-the-Loop

The Hive Mind strictly follows a **feature branch workflow**. Agents work on isolated branches via git worktrees, verify their own work against the knowledge base, then submit a **Pull Request**. The user reviews the PR — checking both the deliverable and the knowledge base update — before merging into `main`. No agent ever commits directly to `main`. The user is the final gatekeeper for what enters the shared mental model.

## Architecture

### Two-Repo Model

The architecture separates **tools** from **content** across two repositories:

| Repository | Purpose | Visibility |
|---|---|---|
| [`ocampbell-stack/aura`](https://github.com/ocampbell-stack/aura) | Skills, templates, and scaffolding tooling. Fork of [cdimoush/aura](https://github.com/cdimoush/aura) extended with 5 `hive.*` skills. Source of truth for all skill definitions. | Public (shareable) |
| `ocampbell-stack/hive-mind` (this repo) | The knowledge base, protocols, and fleet scripts. All context is private. Skills are deployed here via `aura init --force` and gitignored. | Private |

This separation means the tooling can be shared, reused, or contributed back upstream, while the knowledge base — which may contain professional team models and strategic context — remains private.

### Agent Coordination via Beads

All agent coordination runs through [beads](https://github.com/steveyegge/beads), a git-native issue tracker designed for AI agents. There is no separate coordination repo or dashboard — beads provides everything natively:

- **Task management** — Dependency-aware issue tracking with `bd ready`, `bd create`, `bd close`
- **Atomic claiming** — Race-safe task assignment via compare-and-swap (`bd update --claim`)
- **Inter-agent messaging** — `bd mail` for agent-to-agent communication
- **Fleet visibility** — `bd swarm status`, `bd audit`, `bd graph`
- **Session context** — `bd prime` automatically injects task state at session start

The `.beads/` database is shared across all worktrees, so every agent sees the same task state regardless of which branch they're on.

### Parallel Execution via Worktrees

Each agent operates in its own git worktree — an isolated checkout of the same repository on its own branch. This enables true parallel work without file conflicts:

```
~/Sandbox/agent-workspace/
    ├── hive-mind-main/      Command Post (user's primary window, main branch)
    ├── agent-alpha/          Worktree on agent-alpha/workspace branch
    └── agent-beta/           Worktree on agent-beta/workspace branch
```

Agents resolve their identity from their working directory path. Worktrees are created via `scripts/setup-fleet.sh` and cleaned up via `scripts/cleanup.sh`.

### Knowledge Base

The knowledge base is structured for a large (100+ file) scale with an index system that lets agents find relevant context without reading everything:

```
knowledge-base/
    ├── INDEX.md               Master index: topic -> file path, with staleness metadata
    ├── strategic-context/     User's role, priorities, OKRs, organizational position
    ├── projects/              Per-project directories with charters, milestones, decisions
    ├── team/                  Professional models of team members (INTERNAL ONLY)
    └── workstreams/           Active workstream status, owners, blockers
```

Every KB file carries YAML frontmatter tracking its source, ingestion date, confidence level, and last verification date. The `/hive.groom` skill uses this metadata to flag stale or contradictory entries.

## Privacy & Professionalism

This repository may contain professional models of real people — their working styles, capabilities, communication preferences, and professional assessments. These models exist solely to help agents tailor their work and recommendations. They are governed by strict standards:

- **Performance-review standard**: Entries about team members must be truthful, professional, and respectful — written as if they could be read by the subject.
- **Internal only**: Team models never appear in external deliverables. Agents use them to *inform* their work, never to *expose* the reasoning.
- **Leak test**: Before finalizing any internal or external output, agents verify: "If this artifact was obtained by a 3rd-party, outside of the private repository, would anything be embarrassing, inappropriate, or a breach of trust?"
- **Minimal personal information**: Agents include only what's necessary. External deliverables are scanned for extraneous personal details before submission.

See [`protocols/privacy-standards.md`](protocols/privacy-standards.md) for the full policy.

## Getting Started

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — Anthropic's CLI
- [beads](https://github.com/steveyegge/beads) (`bd`) — Git-native issue tracking
- [aura](https://github.com/ocampbell-stack/aura) — Skill scaffolding (our fork)
- [GitHub CLI](https://cli.github.com/) (`gh`) — Authenticated for PR creation
- [uv](https://github.com/astral-sh/uv) — Python package manager

### Setup

```bash
# Clone the repo
git clone https://github.com/ocampbell-stack/hive-mind.git hive-mind-main
cd hive-mind-main

# Deploy skills from aura fork
cp .claude/settings.json .claude/settings.json.bak
aura init --force
cp .claude/settings.json.bak .claude/settings.json

# Create agent worktrees
./scripts/setup-fleet.sh alpha beta

# Verify
aura check && bd ready && gh auth status
```

### Your First Task

```bash
cd ../agent-alpha
claude
# "Use /hive.ingest to read [your document]. Create branch feat/ingest-[topic].
#  Update the knowledge base and INDEX.md. Submit a PR when done."
```

## Repository Structure

```
hive-mind-main/
    ├── CLAUDE.md              Agent operating instructions (loaded every session)
    ├── AGENTS.md              Beads task management guide
    ├── knowledge-base/        The persistent mental model
    │   └── INDEX.md           Master index with staleness tracking
    ├── protocols/             Detailed agent workflow standards
    │   ├── compound-deliverable.md
    │   ├── pr-template.md
    │   ├── privacy-standards.md
    │   └── verification.md
    ├── scripts/               Fleet management utilities
    │   ├── setup-fleet.sh     Create agent worktrees
    │   ├── dashboard.sh       Query beads for fleet status
    │   └── cleanup.sh         Prune merged branches and worktrees
    ├── .beads/                Shared task database (across all worktrees)
    ├── .aura/                 Vision capture and plan staging
    └── .claude/
        ├── settings.json      SessionStart hook (bd prime + KB INDEX)
        └── skills/            Deployed from aura fork (gitignored)
```

## Tooling Stack

| Tool | Role |
|---|---|
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | AI agent runtime |
| [beads](https://github.com/steveyegge/beads) | Dependency-aware task tracking and multi-agent coordination |
| [aura](https://github.com/ocampbell-stack/aura) (fork) | Skill definitions, templates, vision capture, task decomposition |
| [GitHub CLI](https://cli.github.com/) | PR creation and repo management |
| Git worktrees | Parallel agent execution with isolated branches |
