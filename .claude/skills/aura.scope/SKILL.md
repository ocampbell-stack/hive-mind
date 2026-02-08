---
name: aura.scope
description: Research codebase and produce a scope file from a template
argument-hint: <vision description>
disable-model-invocation: true
allowed-tools: Bash(ls *), Read, Write, Glob, Grep
---

# Scope Feature

Research the codebase against a user's vision, select a template, populate it, and write a scope file.

## Input

The argument is a vision description - what the user wants to achieve.

## Steps

1. **Discover templates** - List available templates:
   ```bash
   ls .claude/templates/
   ```
   Read each template to understand what sections it expects.

2. **Select template** - Choose the template that best fits the vision. Default to `feature.md` if unsure.

3. **Research codebase** - Explore the codebase to understand:
   - Existing architecture and patterns
   - Files that will be affected
   - Constraints and dependencies
   - How similar features are implemented

4. **Populate template** - Fill in every section of the template with findings from research. Replace all `<placeholder>` markers with real content.

5. **Write scope file** - Save to `.aura/plans/queue/<kebab-case-name>/scope.md`
   - Generate name from the vision (max 50 chars, lowercase, hyphens)
   - Create the subdirectory if needed

6. **Report** - Tell the user where the scope file was saved and suggest reviewing it before running `/aura.execute`

## Task Format

The task list in the scope file MUST use the standard epic task format so it is compatible with `create_beads` parsing:

```
N. [ ] <Task title> - <Brief description>
N. [ ] <Task title> (depends on X, Y) - <Brief description>
```

Number tasks sequentially across phases. Dependencies reference task numbers.

## Guidelines

- Research thoroughly before writing - read relevant files, understand patterns
- Tasks should be actionable and specific
- A task should do one thing: research, implement, or verify - not all three
- Each task should be completable in one work session
- Dependencies should form a DAG (no cycles)
- Keep phases to 3-5 tasks each
- Include a Dependencies section summarizing the dependency graph
