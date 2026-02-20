---
name: pre
description: Pre-flight risk assessment before work begins.
---

# Pre-Task Forecast

You are running a **pre-task assessment** to forecast how likely you are to complete the upcoming task accurately. Evaluate the task BEFORE doing any work. Be honest about your limitations.

## Process

### Step 0: Context Gate

Before running a forecast, verify the task description is sufficient. Check:
1. **Is the task description detailed enough to forecast against?** — If the task is a single vague sentence like "fix the bug" or "improve performance" with no specifics, STOP.
2. **Do you understand the project context?** — If you have no idea what the codebase does or what the task relates to, STOP.

If any check fails, output a **CONTEXT INSUFFICIENT** block instead of a forecast:
```
CONTEXT INSUFFICIENT
═══════════════════════════════════════
Cannot provide a meaningful forecast. Missing:
• [what's missing — e.g., "Task description is too vague to forecast against"]
• [what's needed — e.g., "Provide specifics: what bug? In what file? What behavior?"]

Action required:
1. [specific step the user should take]
2. [specific step the user should take]
```

Do NOT produce scores without sufficient task detail. A forecast against a vague task is meaningless.

### Step 1: Restate the task

What is the user asking you to do? Be precise.

### Step 2: Check for project standards

Search for documented standards and architectural decisions that may be relevant to the upcoming task:

1. **Standards files** — Use Read to check for `CLAUDE.md` and `AGENTS.md` in the project root. Note any conventions, required patterns, or constraints they define.
2. **ADR files** — Use Glob to search for architectural decision records: `docs/adr/*.md`, `docs/decisions/*.md`, `adr/*.md`, `decisions/*.md`, `doc/architecture/decisions/*.md`, `**/ADR-*.md`. Read any that exist.
3. **Project maturity check** — If no ADR files are found, run `git rev-list --count HEAD` to check the commit count. Projects with 50+ commits but no ADRs may benefit from an advisory.

**Important:** If standards files exist but contain no actionable conventions or constraints (e.g., only a project description), treat it as if no standards were found.

Record what you find — relevant standards feed into Ambiguities and Predicted Pitfalls evaluations. This step does NOT add a new scoring dimension; it informs the existing ones.

### Step 3: Evaluate clarity

   - Is the task specific enough to act on?
   - What is ambiguous or underspecified?
   - What questions SHOULD be asked before starting?

### Step 4: Evaluate feasibility

   - Is this within your capabilities as an LLM?
   - What parts are you confident about?
   - What parts are risky or at the edge of your ability?
   - Does this require information you might not have?

### Step 5: Predict pitfalls

   - Where are errors most likely to occur?
   - What assumptions will you need to make?
   - What are the most common mistakes for this type of task?
   - What would cause a complete failure vs. a partial success?
   - **Reinvention risk** — Does this task involve building something from scratch in a domain that has well-established, battle-tested solutions? Flag if the task proposes custom implementations of: cryptography, authentication/authorization, input sanitization, date/time handling, data validation, or other domains where hand-rolling is known to produce subtle, dangerous bugs. Suggest established alternatives.

### Step 6: Calculate confidence forecast

Score 0-100. This is a PREDICTION, not a post-hoc evaluation. Be conservative. Weight feasibility and pitfall risk heavily.

Calibration anchors — use these to avoid compressing all scores into 70-85:
- **0-30:** Near-certain failure — task is beyond LLM capabilities, critically underspecified, or requires information you definitely don't have
- **31-50:** High risk — significant unknowns, task is at the edge of your ability, or multiple pitfalls are likely
- **51-70:** Moderate risk — feasible but with notable uncertainties, some assumptions required, partial failure likely
- **71-85:** Good chance of success — task is clear, within capabilities, with manageable risks
- **86-95:** High confidence — straightforward task, well-understood domain, few unknowns
- **96-100:** Virtually never awarded — reserved for trivially simple, completely unambiguous tasks

### Step 7: Write the session log entry

Read `.devils-advocate/session.md` first (if it exists), then use the Write tool to write the full existing contents plus your new entry appended at the end. Create the directory and file if they don't exist. Before writing, use Bash to run `git rev-parse --short HEAD` to get the current commit SHA:

   ```markdown
   ## Check #N — Pre-task | YYYY-MM-DD HH:MM | <git-sha>
   - **Score:** XX/100
   - **Summary:** [2-3 sentence forecast of difficulty and risks]
   ```

After writing the session log entry, also write the full formatted forecast output (everything from the Output Format section) to `.devils-advocate/logs/check-{N}-pre-task-{YYYY-MM-DD}-{HHMM}.md` using the same check number and timestamp. Create the `logs/` directory if it doesn't exist.

## Output Format

```
PRE-TASK FORECAST
═══════════════════════════════════════

Task: [restate the task]

Clarity:      XX/100 — [is the request specific enough?]
Feasibility:  XX/100 — [can this be done well by an LLM?]
Risk Level:   XX/100 — [how likely are significant errors?]

Forecast:     XX/100

Ambiguities:
• [anything unclear or underspecified]

Predicted Pitfalls:
• [where errors are most likely]
• [assumptions that may be wrong]

Reinvention Risk: [only if the task involves building solved problems from scratch]
• [what is being hand-built] → [established solution to consider instead]

Relevant Standards: [only if standards files or ADRs were found]
• [standard/ADR] — [how it applies to this task]

Recommendation: [proceed / clarify first / break into smaller tasks]

Unverified:
• [what you did NOT verify — MANDATORY, at least one item]
• [e.g., "I did not explore all relevant source files"]
• [e.g., "I did not check if dependencies are compatible"]

Advisory: [only if no ADRs found in project with 50+ commits]
This project has XX commits but no architectural decision records.
Consider adopting ADRs to document key decisions.
```

## Rules

- This runs BEFORE any work is done — do not start solving the task
- Be conservative with scores — overconfidence at this stage is the worst outcome
- If clarity is below 60, recommend the user clarify before proceeding
- If feasibility is below 50, say so honestly and suggest alternatives
- Never skip the session log write
- The "Unverified" section is MANDATORY — must list at least one thing. If you claim you verified everything, you're lying.
