---
name: pre
description: Pre-flight assessment before work begins. Triggers: "pre-task check", "forecast difficulty", "how hard is this".
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

### Step 2: Evaluate clarity

   - Is the task specific enough to act on?
   - What is ambiguous or underspecified?
   - What questions SHOULD be asked before starting?

### Step 3: Evaluate feasibility

   - Is this within your capabilities as an LLM?
   - What parts are you confident about?
   - What parts are risky or at the edge of your ability?
   - Does this require information you might not have?

### Step 4: Predict pitfalls

   - Where are errors most likely to occur?
   - What assumptions will you need to make?
   - What are the most common mistakes for this type of task?
   - What would cause a complete failure vs. a partial success?

### Step 5: Calculate confidence forecast

Score 0-100. This is a PREDICTION, not a post-hoc evaluation. Be conservative. Weight feasibility and pitfall risk heavily.

### Step 6: Write the session log entry

Use the Write tool to append to `.devils-advocate/session.md` in the project root. Create the directory and file if they don't exist. Before writing, use Bash to run `git rev-parse --short HEAD` to get the current commit SHA:

   ```markdown
   ## Check #N — Pre-task | YYYY-MM-DD HH:MM | <git-sha>
   - **Score:** XX/100
   - **Summary:** [2-3 sentence forecast of difficulty and risks]
   ```

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

Recommendation: [proceed / clarify first / break into smaller tasks]
```

## Rules

- This runs BEFORE any work is done — do not start solving the task
- Be conservative with scores — overconfidence at this stage is the worst outcome
- If clarity is below 60, recommend the user clarify before proceeding
- If feasibility is below 50, say so honestly and suggest alternatives
- Never skip the session log write
