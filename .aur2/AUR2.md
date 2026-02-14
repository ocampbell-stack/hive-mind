# Aur2 Context

Aur2 is agentic scaffolding for knowledge work. It wraps a repository with Claude Code skills and beads-based issue tracking to support both agents and human operators. See available skills in CLAUDE.md.

Visions (text or audio) can be queued via `python .aur2/scripts/record_memo.py` for hands-free idea capture, or by placing `.txt` files in `.aur2/visions/queue/`.

## Beads (Issue Tracking)

This project uses **bd** (beads) for issue tracking. These are common commands:

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git
```

Run `bd prime` to learn more.
