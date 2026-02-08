# Workstreams

This section tracks active workstreams across projects.

## Structure
Each workstream gets a file:
```
workstreams/
  {workstream-name}.md  - Status, owners, blockers, next steps
```

## Frontmatter
Workstream files should include:
```yaml
---
source: "Status update from [meeting/doc/person]"
ingested: YYYY-MM-DD
confidence: high|medium|low
last_verified: YYYY-MM-DD
tags: [project-name, workstream-type]
status: active|paused|completed|blocked
---
```

## Usage
Agents should consult workstream files when:
- Checking current status before producing deliverables
- Identifying blockers or dependencies
- Preparing status updates or reports
