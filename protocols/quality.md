# Quality Protocol

Quality gates that apply after work is complete. Covers the compound deliverable principle, verification checks, and privacy standards.

## Compound Deliverable

Every task produces up to three outputs depending on task weight:

| Output | Full tasks | Light tasks |
|--------|-----------|-------------|
| **Deliverable** — the requested work product | Required | Required |
| **KB Update** — update `knowledge-base/` and `INDEX.md` with learnings | Required | Skip unless the work directly affects KB |
| **Verification** — run the checks below | Full checklist | Privacy scan only |

**Task weight**: Use judgment. A substantive ingestion, deliverable, or multi-file change is a **full task**. A single-file update, typo fix, or iteration round is a **light task**. When in doubt, use full.

## Verification Checklist

Run these four checks before marking any task complete or creating a PR:

### 1. Fidelity
- Does the deliverable match the task requirements?
- Are all requirements addressed?
- Is the scope correct (not over- or under-delivering)?

### 2. Coherence
- Is the deliverable consistent with existing KB content?
- Do any KB updates contradict existing entries?
- If contradictions exist, which source is authoritative? Update accordingly.

### 3. Privacy
- Does the deliverable contain NO content from `knowledge-base/team/` models?
- No internal-only assessments or personal information?
- Apply the leak test: *"If this were forwarded externally, would anything be embarrassing or a breach of trust?"*

### 4. Professionalism
- Appropriate tone for the audience?
- No casual internal language in formal deliverables?
- Would pass review by a senior stakeholder?

**If any check fails**: Fix the issue, re-run the failed check, and note what was caught in the PR description.

## Privacy Classification

### Internal Only (never in external deliverables)
- **Team models** (`knowledge-base/team/*`): working styles, communication preferences, capability assessments
- **Internal strategic assessments**: competitive analysis, internal risk evaluations
- **Personal information**: contact details, private conversations

### Shareable (may appear in external deliverables)
- **Project facts**: timelines, milestones, technical specifications
- **Public strategic context**: published goals, public announcements
- **Professional roles**: job titles, team structure (without behavioral models)

### Rules
1. Never copy team model content into deliverables or PRs
2. Use team context to *inform* tone, not to *expose* it (say "frame this technically" not "Alice prefers technical framing")
3. Strip internal references from externally-facing output
4. When in doubt, omit — better to under-share than to leak
5. If unsure whether something is internal, ask the user

### Handling Sensitive Requests
If a task requires referencing sensitive information:
1. Use the information to inform your work (reading is fine)
2. Produce the deliverable without the sensitive details
3. Note in the PR: "Informed by internal context; sensitive details omitted"

## KB File Standards

All new or modified KB files must include YAML frontmatter:

```yaml
---
source: "Description of where this information came from"
ingested: YYYY-MM-DD
confidence: high|medium|low
last_verified: YYYY-MM-DD
tags: [relevant, tags]
---
```

**Confidence levels**:
- **high**: Primary source, official record, direct from stakeholder
- **medium**: Second-hand account, meeting notes, summary document
- **low**: Inference, hearsay, outdated document ingested for reference
