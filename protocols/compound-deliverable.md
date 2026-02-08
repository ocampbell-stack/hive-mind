# Compound Deliverable Protocol

Every task completion must produce three outputs. No task is considered done until all three are addressed.

## 1. Deliverable
The primary work product requested by the task:
- Code changes, documents, analysis, recommendations, etc.
- Must directly address the task requirements
- Quality bar: would you be confident presenting this to the stakeholder?

## 2. Knowledge Base Update
Update the hive-mind knowledge base with learnings from this task:
- Add new information discovered during the work
- Update existing entries that are now stale or incorrect
- Create new KB files if a topic doesn't exist yet
- Always update `knowledge-base/INDEX.md` to reflect changes
- Include YAML frontmatter on all new/modified KB files:
  ```yaml
  ---
  source: "Description of where this information came from"
  ingested: YYYY-MM-DD
  confidence: high|medium|low
  last_verified: YYYY-MM-DD
  tags: [relevant, tags]
  ---
  ```

## 3. Verification
Run these four checks before marking any task complete:

### Fidelity Check
- Does the deliverable match the assignment instructions?
- Are all requirements addressed?
- Is the scope correct (not over- or under-delivering)?

### Coherence Check
- Is the deliverable consistent with existing KB content?
- Do any KB updates contradict existing entries?
- If contradictions exist, which source is authoritative?

### Privacy Check
- Does the deliverable contain NO internal team models?
- Is there NO unnecessary personal information?
- Would this be safe if shared externally?

### Professionalism Check
- Is the tone appropriate for the audience?
- Would this be acceptable if leaked?
- Does it represent the organization well?

## Completion
Only after all three outputs are produced and verification passes:
1. Commit changes to feature branch
2. Create PR via `gh pr create`
3. Close the beads task: `bd close <id> --reason "summary"`
