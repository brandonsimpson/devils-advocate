---
name: log
description: Display session log of all checks and scores.
---

# Session Log

Display the critique history for this session.

## Process

1. **Read the session log** — Use the Read tool to read `.devils-advocate/session.md` from the project root.

2. **If the file doesn't exist or is empty** — Report that no checks have been run yet and suggest:
   - `/devils-advocate:critique` — Critique current code or a plan document

3. **If the file exists** — Display its contents and add a brief summary:
   - Total number of checks run
   - Pass rate trend (improving, declining, or stable)
   - Worst result (the check with the most failing criteria)
   - Note: Each entry includes a git SHA linking the check to a specific commit

4. **List individual log files** — Use Glob to check for files in `.devils-advocate/logs/*.md`. If any exist, list their filenames so the user knows which detailed critiques are available to read.

## Output Format

```
SESSION LOG
═══════════════════════════════════════

[contents of .devils-advocate/session.md]

───────────────────────────────────────
Summary: N checks | Trend: [improving/declining/stable]
Worst:   Check #X (Y/Z PASS) @ <sha> — [brief note]

Detailed Logs: [only if .devils-advocate/logs/ has files]
• [filename1]
• [filename2]
```

## Rules

- Just display and summarize — do not re-run any assessments
- If the log is very long (>20 entries), show the last 10 and mention how many were omitted
- Never modify the session log file in this skill
