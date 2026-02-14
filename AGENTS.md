# Agent Instructions

This project uses **bd (beads)** for issue tracking. Run `bd prime` for workflow context.

## Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work (atomic)
bd close <id>         # Complete work
bd sync               # Sync with git
```

## Session Lifecycle

**This project's authoritative session lifecycle is defined in `protocols/autonomous-workflow.md`**, not the generic beads session-close protocol from `bd prime`. Key differences:

- Autonomous agents must create PRs (not just push)
- Bead lifecycle (setup/work/record/close) is defined in `CLAUDE.md`
- Compound deliverable checks are required before closing

See `CLAUDE.md` for the full protocol chain.
