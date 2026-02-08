---
description: "Plan and execute maintenance or improvements to the hive-mind system"
disable-model-invocation: false
---

# /hive.maintain - Maintain the Fleet

Improve tooling, scripts, and infrastructure for the hive-mind system.

## Instructions

1. **Read the maintenance request** or identify improvement opportunity
   - Types: bug fix, script improvement, new automation, protocol update, skill refinement

2. **Consult existing infrastructure**
   - Review relevant scripts in `scripts/`
   - Review CLAUDE.md and `protocols/` for agent behavior docs
   - Review skill definitions in `.claude/skills/`
   - Check `.claude/settings.json` for hook configuration

3. **Scope the change**
   - If the change is complex, use `/aura.scope` for task decomposition
   - If simple, proceed directly

4. **Implement on a feature branch**
   - Create branch: `feat/maintain-{description}`
   - Make changes
   - Test changes:
     - Verify hooks fire correctly (check `.claude/settings.json`)
     - Verify skills load (check SKILL.md frontmatter)
     - Verify beads commands work (`bd ready`, `bd list`)
     - Verify scripts execute without errors

5. **Update documentation**
   - Update CLAUDE.md if agent behavior should change
   - Update protocols if verification or process standards change
   - Update skill SKILL.md files if skill behavior changes

6. **Update KB**
   - Document the change in appropriate KB section
   - Update INDEX.md

7. **Submit PR**
   - Use the PR template from protocols/pr-template.md
   - Include what was changed and why
   - Include test results

## Common Maintenance Tasks
- Update SessionStart hook for new context sources
- Refine skill instructions based on usage patterns
- Add new fleet scripts for common operations
- Update protocols based on lessons learned
- Fix issues with worktree or beads configuration
