---
description: "Ingest documents or notes into the hive-mind knowledge base"
disable-model-invocation: false
---

# /hive.ingest - Update Mental Model

Ingest new documents, notes, or external context into the knowledge base.

## Instructions

1. **Read the provided document(s) or notes**
   - Accept input as: pasted text, file paths, URLs, or conversation context
   - Identify the document type: meeting notes, strategic doc, project charter, status update, etc.

2. **Consult `knowledge-base/INDEX.md`**
   - Find relevant existing KB sections
   - Determine if this is a new topic or an update to existing content

3. **Extract key information**
   - Facts and data points
   - Decisions made and their rationale
   - Relationships between people, projects, and workstreams
   - Open questions and unresolved items
   - Action items and deadlines

4. **Update or create KB files**
   - Place files in the appropriate subdirectory:
     - `strategic-context/` for role, priorities, OKRs
     - `projects/{project-name}/` for project-specific information
     - `team/` for professional team models (INTERNAL ONLY)
     - `workstreams/` for workstream status and tracking
   - If updating existing files, preserve existing content and annotate what changed
   - If creating new files, follow the section README.md for structure

5. **Include YAML frontmatter on all KB files**
   ```yaml
   ---
   source: "Description of the source document"
   ingested: YYYY-MM-DD
   confidence: high|medium|low
   last_verified: YYYY-MM-DD
   tags: [relevant, tags]
   ---
   ```

6. **Update `knowledge-base/INDEX.md`**
   - Add new entries to the Quick Reference table
   - Update the By Section listing
   - Update the file count and last updated date

7. **Create verification task**
   - Run the compound deliverable verification (fidelity, coherence, privacy, professionalism)
   - Create a beads task if follow-up verification is needed: `bd create "Verify ingestion of {source}"`

## Confidence Levels
- **high**: Primary source document, official record, direct from stakeholder
- **medium**: Second-hand account, meeting notes from attendee, summary document
- **low**: Inference, hearsay, outdated document being ingested for reference
