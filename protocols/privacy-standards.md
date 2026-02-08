# Privacy & Professionalism Standards

## Classification

### Internal Only (never include in external deliverables)
- **Team models** (`knowledge-base/team/*`): Working styles, communication preferences, capability assessments
- **Internal strategic assessments**: Competitive analysis, internal risk evaluations
- **Personal information**: Contact details, personal preferences, private conversations

### Shareable (may appear in external deliverables)
- **Project facts**: Timelines, milestones, technical specifications
- **Public strategic context**: Published goals, public announcements
- **Professional roles**: Job titles, team structure (without behavioral models)

## Rules for Agents

1. **Never copy team model content** into deliverables, PRs, or external documents
2. **Use team context to inform tone**, not to expose it (e.g., "frame this technically" rather than "Alice prefers technical framing")
3. **Strip internal references** from any externally-facing output
4. **When in doubt, omit** - it's better to under-share than to leak internal context
5. **Flag uncertainty** - if you're unsure whether something is internal, ask the user before including it

## The Leak Test
Before finalizing any external deliverable, ask:
> "If this document were forwarded to someone outside the organization, would anything in it be embarrassing, inappropriate, or a breach of trust?"

If the answer is yes, revise before submitting.

## Handling Sensitive Requests
If a task requires referencing sensitive information:
1. Use the information to inform your work (reading is fine)
2. Produce the deliverable without the sensitive details
3. Note in the PR description: "Informed by internal context; sensitive details omitted"
