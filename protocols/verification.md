# Verification Protocol

## When to Verify
Run verification checks:
- Before closing any beads task
- Before creating any PR
- Before marking any deliverable as complete
- After any bulk KB update (e.g., ingestion of multiple documents)

## Verification Checklist

### 1. Fidelity
Confirm the work matches what was requested:
- [ ] Re-read the original task description
- [ ] Compare deliverable against each requirement
- [ ] Check for scope creep (did you add unrequested features?)
- [ ] Check for scope gaps (did you miss any requirements?)

### 2. Coherence
Confirm consistency with the knowledge base:
- [ ] Search INDEX.md for related topics
- [ ] Read related KB files
- [ ] Check for contradictions between your work and existing KB content
- [ ] If contradictions exist, determine which source is authoritative and update accordingly

### 3. Privacy
Confirm no internal information leaks:
- [ ] Search deliverable for team member names (cross-reference with `knowledge-base/team/`)
- [ ] Check for internal-only assessments or opinions
- [ ] Verify no personal information is exposed
- [ ] Apply the leak test (see privacy-standards.md)

### 4. Professionalism
Confirm external-facing quality:
- [ ] Appropriate tone for the audience
- [ ] No casual internal language in formal deliverables
- [ ] Proper formatting and structure
- [ ] Would pass review by a senior stakeholder

## Handling Failures
If any check fails:
1. Fix the issue before proceeding
2. Re-run the failed check
3. Document what was caught and fixed in the PR description
4. If the fix requires significant rework, update the beads task with a comment

## Automated Checks (Future)
As the system matures, consider adding:
- Pre-commit hooks that scan for team member names in non-team files
- Frontmatter validation (required fields present, dates valid)
- INDEX.md consistency check (all referenced files exist)
