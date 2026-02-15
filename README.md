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

Every substantive task assigned to an agent produces up to three outputs:

1. **The External Deliverable** — The actual work product requested: code, a document, an analysis, a recommendation.
2. **The Internal Context Update** — An update to the Hive Mind knowledge base reflecting what the agent learned or what changed.
3. **Verification** — Checks that the deliverable is faithful to the assignment, consistent with existing knowledge, and compliant with privacy standards.

The rationale: we must assume the *next* agent will need to know what this agent just learned. By encoding this "mental model update" into the repo with every task, we eliminate the need to manually re-paste context for future work. The knowledge base compounds over time — each task leaves the system smarter than it found it.

Task weight determines rigor: substantive work requires all three outputs, while light tasks (small fixes, iterations) require only the deliverable and a privacy scan. See [`protocols/quality.md`](protocols/quality.md) for the full framework.

### Agent Workflows

Agents in this fleet execute specific workflows, each backed by a dedicated Claude Code skill:

| Workflow | Skill | Description |
|---|---|---|
| **Ingest Context** | `/hive.ingest` | Incorporate new reference documents, meeting notes, or user observations into the knowledge base. Tag information with source, date, and confidence level for staleness tracking. |
| **Groom the Mental Model** | `/hive.groom` | Proactively audit the knowledge base for stale information, contradictions between entries, and gaps where referenced topics lack documentation. Surface questions for the user to resolve ambiguities. |
| **Produce Deliverables** | `/hive.deliver` | Generate stakeholder-facing outputs — documents, code, plans, analyses — grounded in the current state of the knowledge base. Every claim traceable to a KB source. |
| **Recommend Engagement** | `/hive.advise` | Analyze meeting minutes, chat threads, or communications and recommend specific actions: feedback to give, questions to ask, risks to flag. Informed by team models and project context but never exposing internal assessments. |
| **Iterate on Feedback** | `/hive.iterate` | Address PR review feedback on an existing feature branch. Read comments, make changes, push updates. |

For task decomposition, agents also have `/aur2.scope` and `/aur2.execute`. When a task is too complex for a single session, the agent escalates to `/aur2.scope`, which produces a work breakdown and submits it as a PR for user review. After the user approves, `/aur2.execute` is invoked separately to create beads and implement the work. Both skills are domain-aware — they detect whether they're operating in a codebase or knowledge base and select the appropriate template and research strategy.

### Human-in-the-Loop

The Hive Mind uses two complementary checkpoints to keep agents aligned with user intent:

1. **Preliminary Alignment** (before implementation) — Before making changes, agents explore the knowledge base for relevant context, assess the impact of the proposed work, and confirm their approach with the user. For high-impact or ambiguous tasks, agents pause and ask clarifying questions. For clear, narrowly-scoped tasks, they state their plan and proceed. This catches misunderstandings at the lowest-cost moment — before any work is done.

2. **PR Review** (after implementation) — Agents work on isolated feature branches and submit a Pull Request. The user reviews both the deliverable and the KB update before merging. The user can provide feedback via PR comments, and the agent iterates via `/hive.iterate`.

These checkpoints apply across two operating modes:

- **Manual mode** (Command Post): The user drives an agent directly, reviewing changes in real time. May commit to main.
- **Autonomous mode** (Agent worktrees): Full branching lifecycle required. Create feature branch, do work, submit PR, wait for review.

See `protocols/alignment.md` for the alignment protocol and `protocols/workflow.md` for the full lifecycle.

## Architecture

### Two-Repo Model

The architecture separates **tools** from **content** across two repositories:

| Repository | Purpose | Visibility |
|---|---|---|
| [`ocampbell-stack/aur2`](https://github.com/ocampbell-stack/aur2) | Skills, templates, and scaffolding tooling. Fork of [cdimoush/aura](https://github.com/cdimoush/aura) with domain-aware scope/execute and `hive.*` skills for knowledge work. Source of truth for all skill definitions. | Public |
| Your private instance (created from this template) | The knowledge base, protocols, and fleet scripts. All context is private. Skills are deployed here via `aur2 init --force --skip-settings` and gitignored. | Private |

This separation means the tooling can be shared, reused, or contributed back upstream, while the knowledge base — which may contain professional team models and strategic context — remains private.

### Agent Coordination via Beads

All agent coordination runs through [beads](https://github.com/steveyegge/beads), a git-native issue tracker designed for AI agents:

- **Task management** — Dependency-aware issue tracking with `bd ready`, `bd create`, `bd close`
- **Atomic claiming** — Race-safe task assignment via compare-and-swap (`bd update --claim`)
- **Inter-agent context passing** — `bd comments add` records what was done, key decisions, and files changed on each bead. The next agent reads this context via `bd show <id>` before starting work. This is the primary mechanism for knowledge transfer between agents.
- **Fleet visibility** — `bd status`, `bd blocked`, `bd graph`
- **Session context** — `bd prime` automatically injects task state at session start
- **Complexity escalation** — Single-session tasks run as one bead. Multi-session work is escalated to `/aur2.scope`, which produces a work breakdown and submits it as a PR for user review. After approval, `/aur2.execute` creates a dependency graph of beads and implements the work. The scope skill selects from domain-appropriate templates (`knowledge-project.md` or `research.md` for KB work, `feature.md` or `bug.md` for code)

#### Bead Lifecycle in Skills

Every `hive.*` skill follows a standard bead lifecycle:

```
Setup → Align → Work → Record → Close
```

1. **Setup** — Claim an existing bead or create a new one. Read prior context via `bd show`.
2. **Align** — Gather relevant KB context, assess impact, and confirm approach with the user before making changes. See `protocols/alignment.md`.
3. **Work** — Execute the skill's core instructions.
4. **Record** — `bd comments add` with a structured summary (what was done, decisions, files changed).
5. **Close** — `bd close --reason "summary" --suggest-next` to complete and surface newly unblocked work.

Skills may also create follow-up beads for discovered work (e.g., `hive.groom` creates remediation beads, `hive.advise` creates action item beads). These follow-up beads feed the `bd ready` queue for other agents to pick up.

### Parallel Execution via Worktrees

Each agent operates in its own git worktree — an isolated checkout of the same repository on its own branch:

```
~/your-workspace/
    ├── hive-mind-main/      Command Post (user's primary window, main branch)
    ├── agent-alpha/          Worktree on agent-alpha/workspace branch
    └── agent-beta/           Worktree on agent-beta/workspace branch
```

Agents resolve their identity from their working directory path. Worktrees are created via `scripts/setup-fleet.sh`. After merging a PR, run `scripts/cleanup.sh <agent>` (or `--all`) from Command Post to reset worktrees and clean up branches.

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

See [`protocols/quality.md`](protocols/quality.md) for the full policy.

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

See [`docs/operations.md`](docs/operations.md) for the full day-to-day operations guide — fleet monitoring, beads triage, multi-agent coordination, and PR review workflow.

Once your instance is running, try these first tasks:

1. **Ingest context**: `/hive.ingest` some notes about your role, current projects, or team
2. **Check the KB**: Look at `knowledge-base/INDEX.md` to see what was added
3. **Groom**: `/hive.groom` to audit the KB for gaps
4. **Produce a deliverable**: `/hive.deliver` a document grounded in your KB context

## Repository Structure

```
hive-mind-main/
    ├── CLAUDE.md              Agent operating instructions (loaded every session)
    ├── docs/
    │   └── operations.md      Day-to-day fleet management guide
    ├── knowledge-base/        The persistent mental model
    │   └── INDEX.md           Master index with staleness tracking
    ├── protocols/             Detailed agent workflow standards
    │   ├── alignment.md       Pre-implementation alignment protocol
    │   ├── quality.md         Verification, privacy, and deliverable standards
    │   └── workflow.md        Mode detection, skill lifecycle, branching, PR lifecycle
    ├── scripts/               Fleet management utilities
    │   ├── setup-fleet.sh     Create agent worktrees
    │   ├── dashboard.sh       Query beads for fleet status
    │   └── cleanup.sh         Post-merge cleanup (reset worktrees, delete merged branches)
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
