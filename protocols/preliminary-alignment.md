# Preliminary Alignment Protocol

Before making changes, agents gather context, assess impact, and confirm their approach with the user.

## Why

PR review catches problems after implementation. Preliminary alignment catches misunderstandings **before** implementation — when the cost of correction is lowest. Together they form two complementary checkpoints: align first, then implement, then review.

## Three Steps

### 1. Context Gathering

- Read `knowledge-base/INDEX.md` to identify relevant entries
- Read the KB files, protocols, and existing content that relate to the request
- Note what already exists — understanding the current state prevents redundant or contradictory work

### 2. Impact Assessment

- What files will be created, modified, or reorganized?
- Does the proposed work overlap with or contradict existing content?
- Are there ambiguities in the request that could lead to wrong outcomes?
- What assumptions are you making?

### 3. Alignment Check

Present your findings to the user in this format:

- **Context found**: Relevant KB entries read, key facts discovered
- **Interpretation**: Your understanding of what's being asked
- **Proposed approach**: What you plan to do — files to create/modify, structure decisions
- **Questions**: Anything ambiguous or requiring user input

Then seek confirmation before proceeding.

## Confidence Threshold

Not every task requires a hard pause. Use judgment based on impact and clarity:

**Always pause** (use `AskUserQuestion` and wait for confirmation):
- Creating new files or KB entries
- Reorganizing existing structure
- Modifying multiple existing files
- The request is ambiguous or could be interpreted multiple ways
- You are making assumptions about intent

**State plan and proceed** (output your assessment, continue unless user intervenes):
- Updating a single file with clear, factual changes
- Following explicit, detailed instructions from the user
- The task is narrowly scoped with an obvious approach

**When in doubt, pause.** The cost of asking is always lower than the cost of rework.

## Mode Behavior

This protocol applies in both operating modes:

- **Manual mode**: The user is present and can interrupt. Output your assessment; use `AskUserQuestion` for ambiguous or high-impact work.
- **Autonomous mode**: `AskUserQuestion` blocks until the user responds, which is the desired behavior for high-impact work. For clear, narrowly-scoped tasks, state your plan and proceed — the PR review gate is still in place as a safety net.

## Relationship to Other Protocols

- **Compound deliverable**: Preliminary alignment happens before work begins; compound deliverable verification happens after work is complete. Both are required.
- **Complexity escalation**: For multi-session work, `/aur2.scope` already produces a scope PR for review. Preliminary alignment is a lighter version of this same principle, applied to single-session work.
- **PR review**: The post-implementation safety net. Preliminary alignment reduces the number of issues that reach this stage.
