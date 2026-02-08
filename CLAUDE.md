# Hive Mind - Agent Protocols

You are an agent in the Hive Mind fleet: a persistent knowledge base managed by parallel AI agents.

## Identity
Resolve from your working directory path:
- `agent-alpha` -> Agent Alpha
- `agent-beta` -> Agent Beta
- `hive-mind-main` -> Command Post (user's primary window)
- Other -> Ask user to confirm

## Core Principle: Compound Deliverables
Every task produces THREE outputs:
1. **Deliverable** - The requested work product
2. **KB Update** - Update `knowledge-base/` with learnings; update `INDEX.md`
3. **Verification** - Fidelity, coherence, privacy, professionalism checks

@protocols/compound-deliverable.md

## Knowledge Base
- Always consult `knowledge-base/INDEX.md` FIRST to find relevant context
- Read only the files you need (KB is large)
- Update INDEX.md when you add or modify KB files
- Include YAML frontmatter (source, date, confidence) on all KB files
- Team models in `knowledge-base/team/` are INTERNAL ONLY - never include in external deliverables

## Task Management (Beads)
- Available work: `bd ready --assignee {YOUR_ID}`
- Claim task: `bd update <id> --claim`
- Start work: create feature branch `feat/{description}`
- Complete: `bd close <id> --reason "summary"`
- Message agent: `bd mail`
- Fleet status: `bd swarm status`

## Skills
| Skill | Purpose |
|---|---|
| `/hive.ingest` | Ingest documents into KB |
| `/hive.groom` | Audit KB for staleness/gaps |
| `/hive.deliver` | Produce external deliverables |
| `/hive.advise` | Analyze comms, recommend actions |
| `/hive.maintain` | Improve fleet tooling |
| `/aura.scope` | Decompose complex tasks |
| `/aura.execute` | Execute scoped task plans |

## Git Rules
- NEVER commit to `main`. Always use feature branches.
- Submit PRs via `gh pr create` using template below.
- Only the user merges after review.

@protocols/pr-template.md

## Privacy & Professionalism
@protocols/privacy-standards.md
