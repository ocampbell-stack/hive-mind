# Aura Context

Aura is agentic scaffolding that wraps a codebase to make life easier for both agents and human developers. It provides skills for planning and writing code — see available skills in CLAUDE.md.

Visions (text or audio) can be queued via `python .aura/scripts/record_memo.py` for hands-free idea capture, or by placing `.txt` files in `.aura/visions/queue/`.

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
