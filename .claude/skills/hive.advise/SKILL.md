---
description: "Analyze communications and recommend engagement actions"
disable-model-invocation: false
---

# /hive.advise - Recommend Engagement

Analyze communications and recommend actions based on KB context.

## Instructions

1. **Read the provided communication**
   - Accept: meeting notes, chat threads, emails, Slack messages, etc.
   - Identify: participants, topics discussed, decisions made, action items, tone

2. **Load relevant KB context**
   - Consult `knowledge-base/INDEX.md` for:
     - Team member models (if applicable, for tailoring recommendations)
     - Project state and priorities
     - Strategic context and objectives
     - Related workstream status

3. **Produce recommendations**
   Structure your output as:

   ### Action Items
   - Specific things the user should do, with rationale grounded in KB context
   - Prioritized by urgency and strategic alignment

   ### Suggested Responses / Talking Points
   - Draft responses or key points for follow-up communications
   - Tailored to the audience (informed by team models, not exposing them)

   ### Risks & Sensitivities
   - Political or interpersonal dynamics to be aware of
   - Strategic risks identified from the communication
   - Topics that need careful handling

   ### New Information Detected
   - Facts, decisions, or context from the communication that should be ingested into KB

4. **Privacy gate**
   - Ensure recommendations don't expose internal team models
   - Frame advice in terms of "what to do" not "why based on person X's model"
   - If the user asks for an external-facing response, run the full privacy check

5. **Update KB**
   - Ingest new information gleaned from the communication
   - Update relevant project, workstream, or team files
   - Update INDEX.md

6. **Create follow-up tasks**
   - Create beads tasks for any action items that need tracking
   - `bd create "Follow up: {action item description}"`
