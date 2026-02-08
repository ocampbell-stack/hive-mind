---
description: "Produce external deliverables grounded in hive-mind context"
disable-model-invocation: false
---

# /hive.deliver - Produce External Deliverables

Generate stakeholder-facing outputs grounded in KB context.

## Instructions

1. **Read the deliverable request**
   - Understand the audience, format, and purpose
   - Identify the type: document, code, plan, presentation, analysis, email, etc.

2. **Load relevant context from KB**
   - Consult `knowledge-base/INDEX.md` to identify all relevant files
   - Read project files, strategic context, and workstream status as needed
   - Read team models ONLY for informing approach (never for content)

3. **Draft the deliverable**
   - Match the requested format and tone
   - Ground all claims in KB content (cite internally which KB files informed each section)
   - Maintain appropriate level of detail for the audience

4. **Run compound deliverable verification**

   a. **Fidelity**: Does it match the assignment instructions?
      - Re-read the original request
      - Check every requirement is addressed
      - Verify scope is correct

   b. **Coherence**: Is it consistent with the KB?
      - Cross-reference facts, dates, and claims against KB files
      - Flag any information that couldn't be verified in KB

   c. **Privacy**: Does it contain NO internal team models or unnecessary personal info?
      - Search for team member names and verify no model content leaked
      - Check for internal-only assessments
      - Apply the leak test from privacy-standards.md

   d. **Professionalism**: Would this be appropriate if leaked?
      - Check tone and language
      - Verify formatting meets stakeholder expectations

5. **Update KB with learnings**
   - If the deliverable process revealed new information, ingest it
   - If existing KB content was found to be stale or wrong, flag for grooming

6. **Submit deliverable**
   - Place on feature branch
   - Create PR via `gh pr create` using the PR template from protocols/pr-template.md
   - Close beads task with summary
