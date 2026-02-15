# Alignment Protocol

Before making changes, gather context, assess impact, and confirm your approach. This catches misunderstandings *before* implementation — when correction cost is lowest.

## Three Steps

### 1. Context Gathering
- Read `knowledge-base/INDEX.md` to identify relevant entries
- Read the KB files, protocols, and existing content related to the request
- Note what already exists — prevents redundant or contradictory work

### 2. Impact Assessment
- What files will be created, modified, or reorganized?
- Does the proposed work overlap with or contradict existing content?
- Are there ambiguities that could lead to wrong outcomes?
- What assumptions are you making?

### 3. Alignment Check

Present your findings:
- **Context found**: Relevant KB entries read, key facts discovered
- **Interpretation**: Your understanding of what's being asked
- **Proposed approach**: Files to create/modify, structure decisions
- **Questions**: Anything ambiguous or requiring user input

Then seek confirmation before proceeding.

## Confidence Threshold

Not every task requires a hard pause. Use judgment based on impact and clarity:

**Always pause** (use `AskUserQuestion` and wait):
- Creating new files or KB entries
- Reorganizing existing structure
- Modifying multiple existing files
- The request is ambiguous or could be interpreted multiple ways
- You are making assumptions about intent

**State plan and proceed** (output assessment, continue unless user intervenes):
- Updating a single file with clear, factual changes
- Following explicit, detailed instructions
- The task is narrowly scoped with an obvious approach
- You have a bead assignment with a clear description (the bead IS pre-authorization)

**When in doubt, pause.** The cost of asking is always lower than the cost of rework.

## Mode Behavior

- **Manual mode**: The user is present and can interrupt. Output your assessment; use `AskUserQuestion` for ambiguous or high-impact work.
- **Autonomous mode**: `AskUserQuestion` blocks until the user responds — desired for high-impact work. For clear, narrowly-scoped bead assignments, state your plan and proceed. The PR review gate is still in place.
