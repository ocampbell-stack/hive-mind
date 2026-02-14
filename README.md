# Hive Mind

A persistent, version-controlled knowledge base managed by parallel AI agents. The Hive Mind treats the user's mental model of their work as a living repository — strategic context, project state, team dynamics, and work products — maintained and extended by a fleet of Claude Code agents operating through git worktrees.

> **Your instance should be private.** It will contain models of team members and sensitive strategic context. See [Privacy & Professionalism](#privacy--professionalism) below.

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

### Agent Workflows

Agents in this fleet execute specific workflows, each backed by a dedicated Claude Code skill:

| Workflow | Skill | Description |
|---|---|---|
| **Ingest Context** | `/hive.ingest` | Incorporate new reference documents, meeting notes, or user observations into the knowledge base. Tag information with source, date, and confidence level for staleness tracking. |
| **Groom the Mental Model** | `/hive.groom` | Proactively audit the knowledge base for stale information, contradictions between entries, and gaps where referenced topics lack documentation. Surface questions for the user to resolve ambiguities. |
| **Produce Deliverables** | `/hive.deliver` | Generate stakeholder-facing outputs — documents, code, plans, analyses — grounded in the current state of the knowledge base. Every claim traceable to a KB source. |
| **Recommend Engagement** | `/hive.advise` | Analyze meeting minutes, chat threads, or communications and recommend specific actions: feedback to give, questions to ask, risks to flag. Informed by team models and project context but never exposing internal assessments. |
| **Maintain the Fleet** | `/hive.maintain` | Improve the Hive Mind's own tooling, scripts, skills, and infrastructure. The system maintains itself. |
| **Iterate on Feedback** | `/hive.iterate` | Address PR review feedback on an existing feature branch. Read comments, make changes, push updates. |

For task decomposition and execution, agents also have `/aur2.scope` and `/aur2.execute`.

### Human-in-the-Loop

The Hive Mind follows two operating modes:

- **Manual mode** (Command Post): The user drives an agent directly, reviewing changes in real time. May commit to main.
- **Autonomous mode** (Agent worktrees): Agents work on isolated feature branches via git worktrees, verify their own work against the knowledge base, then submit a **Pull Request**. The user reviews the PR — checking both the deliverable and the knowledge base update — before merging into `main`. The user can provide feedback via PR comments, and the agent iterates via `/hive.iterate`.

See `protocols/autonomous-workflow.md` for the full lifecycle.

## Architecture

### Two-Repo Model

The architecture separates **tools** from **content** across two repositories:

| Repository | Purpose | Visibility |
|---|---|---|
| [`ocampbell-stack/aur2`](https://github.com/ocampbell-stack/aur2) | Skills, templates, and scaffolding tooling. Fork of [cdimoush/aura](https://github.com/cdimoush/aura) extended with `hive.*` skills for knowledge work. Source of truth for all skill definitions. | Public |
| Your private instance (created from this template) | The knowledge base, protocols, and fleet scripts. All context is private. Skills are deployed here via `aur2 init --force --skip-settings` and gitignored. | Private |

This separation means the tooling can be shared, reused, or contributed back upstream, while the knowledge base — which may contain professional team models and strategic context — remains private.

### Agent Coordination via Beads

All agent coordination runs through [beads](https://github.com/steveyegge/beads), a git-native issue tracker designed for AI agents:

- **Task management** — Dependency-aware issue tracking with `bd ready`, `bd create`, `bd close`
- **Atomic claiming** — Race-safe task assignment via compare-and-swap (`bd update --claim`)
- **Inter-agent context passing** — `bd comments add` records what was done, key decisions, and files changed on each bead. The next agent reads this context via `bd show <id>` before starting work. This is the primary mechanism for knowledge transfer between agents.
- **Inter-agent messaging** — `bd mail` for agent-to-agent communication
- **Fleet visibility** — `bd swarm status`, `bd audit`, `bd graph`
- **Session context** — `bd prime` automatically injects task state at session start
- **Complexity escalation** — Single-session tasks run as one bead. Multi-session work is decomposed via `/aur2.scope` into a dependency graph of beads, then executed via `/aur2.execute`

#### Bead Lifecycle in Skills

Every `hive.*` skill follows a standard bead lifecycle:

```
Setup → Work → Record → Close
```

1. **Setup** — Claim an existing bead or create a new one. Read prior context via `bd show`.
2. **Work** — Execute the skill's core instructions.
3. **Record** — `bd comments add` with a structured summary (what was done, decisions, files changed).
4. **Close** — `bd close --reason "summary" --suggest-next` to complete and surface newly unblocked work.

Skills may also create follow-up beads for discovered work (e.g., `hive.groom` creates remediation beads, `hive.advise` creates action item beads). These follow-up beads feed the `bd ready` queue for other agents to pick up.

### Parallel Execution via Worktrees

Each agent operates in its own git worktree — an isolated checkout of the same repository on its own branch:

```
~/your-workspace/
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
- **Leak test**: Before finalizing any output, agents verify: "If this artifact was obtained by a 3rd-party, would anything be embarrassing, inappropriate, or a breach of trust?"
- **Minimal personal information**: Agents include only what's necessary.

See [`protocols/privacy-standards.md`](protocols/privacy-standards.md) for the full policy.

## Getting Started

### Prerequisites

Install these tools before setting up your instance:

| Tool | Install | Purpose |
|---|---|---|
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | See docs | AI agent runtime |
| [GitHub CLI](https://cli.github.com/) | `brew install gh` | Repo and PR management |
| [uv](https://github.com/astral-sh/uv) | `brew install uv` | Python package manager |
| [beads](https://github.com/steveyegge/beads) | `brew tap steveyegge/beads && brew install beads` | Git-native issue tracking |
| [sox](http://sox.sourceforge.net/) | `brew install sox` | Audio recording (optional, for voice visions) |
| [ffmpeg](https://ffmpeg.org/) | `brew install ffmpeg` | Audio processing (optional, for voice visions) |

After installing `gh`, authenticate: `gh auth login`

### Step 1: Create Your Private Instance

This repo is a **GitHub template**. Create your own private instance:

```bash
gh repo create my-hive-mind --template ocampbell-stack/hive-mind --private --clone
cd my-hive-mind
```

Or click **"Use this template"** on GitHub and select **Private**.

### Step 2: Install Aur2

[Aur2](https://github.com/ocampbell-stack/aur2) provides the skills and scaffolding. Install it once per machine:

```bash
git clone https://github.com/ocampbell-stack/aur2.git ~/aur2
cd ~/aur2
uv venv && source .venv/bin/activate
uv pip install -e .
aur2 --version   # Should print: aur2, version 0.1.0
```

Add aur2 to your PATH (add to your shell profile):
```bash
export PATH="$HOME/aur2/.venv/bin:$PATH"
```

### Step 3: Deploy Skills and Set Up Fleet

```bash
cd ~/my-hive-mind   # or wherever you cloned your instance

# Deploy skills from aur2
aur2 init --force --skip-settings

# Create agent worktrees (name your agents whatever you like)
./scripts/setup-fleet.sh alpha beta

# Verify everything works
aur2 check && bd ready && gh auth status
```

This creates the workspace layout:
```
~/
├── my-hive-mind/        Command Post (your primary window, main branch)
├── agent-alpha/          Worktree on agent-alpha/workspace branch
└── agent-beta/           Worktree on agent-beta/workspace branch
```

### Step 4: (Optional) Set Up Voice Visions

If you want to capture ideas via audio recording:

```bash
cp .aur2/.env.example .aur2/.env
# Edit .aur2/.env and add your OpenAI API key

uv venv .aur2/.venv
source .aur2/.venv/bin/activate
uv pip install -r .aur2/scripts/requirements.txt
```

### Assigning Tasks

**Manual mode** — you drive the agent directly:
```bash
cd my-hive-mind
claude
# Work with the agent on main, review changes in real time
```

**Autonomous mode** — delegate work, review via PR:
```bash
cd agent-alpha
claude
> /hive.ingest the attached meeting notes from the design review
# Agent: syncs → branches → works → commits → creates PR
# You: review the PR on GitHub, leave comments if needed
# Agent: /hive.iterate #<PR-number> to address your feedback
```

### What's Next?

Once your instance is running, try these first tasks:

1. **Ingest context**: `/hive.ingest` some notes about your role, current projects, or team
2. **Check the KB**: Look at `knowledge-base/INDEX.md` to see what was added
3. **Groom**: `/hive.groom` to audit the KB for gaps
4. **Produce a deliverable**: `/hive.deliver` a document grounded in your KB context

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
    │   ├── verification.md
    │   ├── autonomous-workflow.md
    │   └── pr-feedback.md
    ├── scripts/               Fleet management utilities
    │   ├── setup-fleet.sh     Create agent worktrees
    │   ├── dashboard.sh       Query beads for fleet status
    │   └── cleanup.sh         Prune merged branches and worktrees
    ├── .beads/                Shared task database (across all worktrees)
    ├── .aur2/                 Vision capture and plan staging
    └── .claude/
        ├── settings.json      SessionStart hook (bd prime + KB INDEX)
        └── skills/            Deployed from aur2 (gitignored)
```

## Tooling Stack

| Tool | Role |
|---|---|
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | AI agent runtime |
| [beads](https://github.com/steveyegge/beads) | Dependency-aware task tracking and multi-agent coordination |
| [aur2](https://github.com/ocampbell-stack/aur2) | Skill definitions, templates, vision capture, task decomposition |
| [GitHub CLI](https://cli.github.com/) | PR creation and repo management |
| Git worktrees | Parallel agent execution with isolated branches |
