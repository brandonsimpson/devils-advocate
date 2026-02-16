---
name: log
description: Display session log of all confidence checks. Triggers: "show confidence log", "show scores", "session log".
---

# Session Log

Display the confidence assessment history for this session.

## Process

1. **Read the session log** — Use the Read tool to read `.devils-advocate/session.md` from the project root.

2. **If the file doesn't exist or is empty** — Report that no checks have been run yet and suggest available commands:
   - `/devils-advocate:critique` — Critique current solution
   - `/devils-advocate:pre` — Pre-task forecast
   - `/devils-advocate:critique-plan <path>` — Review a plan file
   - `/devils-advocate:second-opinion` — Re-critique with a different adversarial lens

3. **If the file exists** — Display its contents and add a brief summary:
   - Total number of checks run
   - Average score across all checks
   - Trend (improving, declining, or stable)
   - Lowest-scoring check (the one that needs most attention)
   - Note: Each entry includes a git SHA linking the check to a specific commit

## Output Format

```
SESSION LOG
═══════════════════════════════════════

[contents of .devils-advocate/session.md]

───────────────────────────────────────
Summary: N checks | Avg: XX/100 | Trend: [improving/declining/stable]
Lowest:  Check #X (XX/100) @ <sha> — [brief note]
```

## Rules

- Just display and summarize — do not re-run any assessments
- If the log is very long (>20 entries), show the last 10 and mention how many were omitted
- Never modify the session log file in this skill
