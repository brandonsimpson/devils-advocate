---
name: confidence-log
description: Use when the user asks to "show confidence log", "view confidence history", "show scores", "confidence session log", or invokes /confidence-loop:confidence-log. Displays the running session log of all confidence checks.
---

# Confidence Session Log Viewer

Display the confidence assessment history for this session.

## Process

1. **Read the session log** — Use the Read tool to read `.confidence-loop/session.md` from the project root.

2. **If the file doesn't exist or is empty** — Report that no confidence checks have been run yet and suggest available commands:
   - `/confidence-loop:confidence` — Assess current solution
   - `/confidence-loop:confidence-pre` — Pre-task forecast
   - `/confidence-loop:confidence-plan <path>` — Review a plan file

3. **If the file exists** — Display its contents and add a brief summary:
   - Total number of checks run
   - Average score across all checks
   - Trend (improving, declining, or stable)
   - Lowest-scoring check (the one that needs most attention)

## Output Format

```
CONFIDENCE SESSION LOG
═══════════════════════════════════════

[contents of .confidence-loop/session.md]

───────────────────────────────────────
Summary: N checks | Avg: XX/100 | Trend: [improving/declining/stable]
Lowest:  Check #X (XX/100) — [brief note]
```

## Rules

- Just display and summarize — do not re-run any assessments
- If the log is very long (>20 entries), show the last 10 and mention how many were omitted
- Never modify the session log file in this skill
