---
name: aura.process_visions
description: Process all visions from queue - text files and audio memos
disable-model-invocation: true
allowed-tools: Bash(python *), Bash(mv *), Read, Write, Glob, Grep, Edit
---

# Process Visions

Process all visions in the queue sequentially.

## Directory Structure

Visions are stored in `.aura/visions/` with the following structure:
- `queue/` - Ready for processing
  - `<title>.txt` - Text vision (plain text file)
  - `<title>/` - Audio vision directory (has audio.wav + transcript.txt)
- `processed/<title>_<timestamp>/` - Successfully processed
- `failed/<title>/` - Failed (may be missing transcript.txt)

## Steps

1. **List queue** - Find all vision items:
   ```bash
   ls -1 .aura/visions/queue/
   ```

2. **For each item**, process sequentially:

   ### Text vision (`.txt` file)

   a. **Read text** - Use Read tool on `.aura/visions/queue/<title>.txt`

   b. **Act on request** - Execute what the user asked for

   c. **On success** - Move to processed:
      ```bash
      mv ".aura/visions/queue/<title>.txt" ".aura/visions/processed/<title>_$(date +%Y%m%d_%H%M%S).txt"
      ```

   ### Audio vision (directory with audio.wav + transcript.txt)

   a. **Check for transcript** - If `transcript.txt` doesn't exist, transcribe first:
      ```bash
      python .aura/scripts/transcribe.py ".aura/visions/queue/<title>/audio.wav" > ".aura/visions/queue/<title>/transcript.txt"
      ```

   b. **Read transcript** - Use Read tool on `.aura/visions/queue/<title>/transcript.txt`

   c. **Act on request** - Execute what the user asked for in the memo

   d. **On success** - Move to processed with timestamp:
      ```bash
      mv ".aura/visions/queue/<title>" ".aura/visions/processed/<title>_$(date +%Y%m%d_%H%M%S)"
      ```

   e. **On failure** - Move to failed with timestamp:
      ```bash
      mv ".aura/visions/queue/<title>" ".aura/visions/failed/<title>_$(date +%Y%m%d_%H%M%S)"
      ```

3. **Continue** - Process next vision without user confirmation

## Acting on Request

- Read the content and determine what the user is asking for
- You can search and read any file in the project for context
- Output (markdown, notes, research results) goes in the vision's directory only — do not modify project files
- Common requests: create a summary, research a topic, draft a plan

## Empty Queue

If `.aura/visions/queue/` is empty or contains only `.gitkeep`, report:
"No visions in queue. Record a new memo with: python .aura/scripts/record_memo.py"

## Error Handling

- If transcription fails, move memo to failed/
- If acting on request fails, move item to failed/
- Always continue to next vision after handling current one
