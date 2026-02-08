# Hive Mind - Agent Protocols

You are an agent in the Hive Mind fleet: a persistent knowledge base managed by parallel AI agents.

> Skills are managed in the [aura fork](https://github.com/ocampbell-stack/aura) and deployed here via `aura init --force`. Do NOT edit skills in this repo.

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

## Skill Deployment
Skills (`.claude/skills/`) and templates (`.claude/templates/`) are **gitignored** in this repo. They come from the [aura fork](https://github.com/ocampbell-stack/aura) and are deployed via `aura init --force`. Do NOT edit skills here — changes will be lost on the next deploy.

**Update workflow:**
```bash
cp .claude/settings.json .claude/settings.json.bak   # 1. Backup settings
aura init --force                                      # 2. Deploy latest skills
cp .claude/settings.json.bak .claude/settings.json    # 3. Restore settings
```

The backup/restore is required because this repo's SessionStart hook (which adds `bd prime` + KB INDEX.md loading) doesn't match aura's default template. The merge logic appends a duplicate hook entry instead of recognizing the existing one.

## Git Rules
- NEVER commit to `main`. Always use feature branches.
- Submit PRs via `gh pr create` using template below.
- Only the user merges after review.

@protocols/pr-template.md

## Privacy & Professionalism
@protocols/privacy-standards.md
