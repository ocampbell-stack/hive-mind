---
description: "Audit knowledge base for staleness, inconsistencies, and gaps"
disable-model-invocation: false
---

# /hive.groom - Groom Mental Model

Proactively audit the KB for staleness, inconsistencies, and gaps.

## Instructions

1. **Determine scope**
   - If a target section is specified, scope to that section
   - If no target specified, audit the full KB
   - Read `knowledge-base/INDEX.md` to get the file listing

2. **For each file in scope, check:**

   a. **Staleness** - Is `last_verified` in frontmatter older than 30 days?
      - Flag as stale with recommended action (re-verify, update, or archive)

   b. **Contradictions** - Cross-reference with related files:
      - Do dates, facts, or decisions conflict between files?
      - Are team assignments consistent across project and workstream files?
      - Do priorities in strategic-context match what's reflected in projects?

   c. **Gaps** - Are there referenced topics without KB entries?
      - Topics mentioned in one file but not documented elsewhere
      - Team members referenced but without team model files
      - Projects mentioned but without project directories

   d. **Structural issues**
      - Files missing required YAML frontmatter
      - Files not listed in INDEX.md
      - Empty or placeholder files that were never populated

3. **Produce a grooming report**
   Output a structured report with:
   - **Stale items**: File path, last verified date, recommended action
   - **Contradictions**: File paths, conflicting statements, which is likely authoritative
   - **Gaps**: Topic, where it's referenced, suggested KB location
   - **Structural issues**: What's wrong and how to fix it
   - **Questions for user**: Things that cannot be resolved autonomously

4. **Update INDEX.md** if structure changed during grooming

5. **Create beads tasks** for each remediation item that requires action:
   - `bd create "KB: Update stale entry {file}"`
   - `bd create "KB: Resolve contradiction between {file1} and {file2}"`
   - `bd create "KB: Fill gap - document {topic}"`

## Grooming Frequency
- Full KB groom: weekly or when explicitly requested
- Section groom: after any major ingestion into that section
- Quick check: before any deliverable that relies on KB context
