---
name: meeting-digest
description: >
  Process a meeting transcript or audio file to extract decisions, action items,
  and open questions. Optionally push action items to Linear or GitHub Issues.
---

# Meeting Digest

## Transcript Location

Transcripts live in `~/meetings/` as `.txt` files (output from `transcribe`).

If the user gives a filename without a path, check `~/meetings/<filename>.txt`.
If they give an audio file path, tell them to run `transcribe <file>` first.

## Processing Steps

1. Read the transcript
2. Extract and structure:
   - **Decisions** — what was agreed, not just discussed
   - **Action items** — who owns it, what they'll do, by when (if mentioned)
   - **Open questions** — unresolved topics that need follow-up
3. Output a clean summary

### Output Format

```
**Meeting:** [inferred title or filename]
**Date:** [if present in transcript]

**Decisions:**
- [decision]

**Action Items:**
- [ ] @person — what they'll do [by date if mentioned]

**Open Questions:**
- [question]
```

## Action Item Follow-through

For action items assigned to the user (look for first-person language:
"I'll", "I will", "I can", or the user's name), ask:
> "Create Linear tickets for your action items, GitHub issues, or just list them?"

- **Linear tickets** → use the `linear-triage` skill
- **GitHub issues** → `gh issue create --title "..." --body "..."`
- **List only** → paste the filtered list

## Whisper Usage Reminder

If given an `.m4a`, `.mp3`, `.wav`, or other audio file:
```
Run: transcribe <file>
This saves a .txt transcript to ~/meetings/ for processing.
```
