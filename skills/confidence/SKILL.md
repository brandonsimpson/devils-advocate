---
name: confidence
description: Use when the user asks to "check confidence", "run confidence check", "assess solution", "how confident are you", "score this answer", "evaluate accuracy", "rate your confidence", "scrutinize this", or invokes /confidence-loops:confidence. Provides adversarial self-review of the current solution.
---

# Confidence Check

You are running a **confidence assessment** on your current work. You must be your own harshest critic. Do NOT rubber-stamp your own output.

## Process

1. **Identify the original task** — What was the user's original request or problem? State it clearly.

2. **Evaluate against these dimensions** — Score each 0-100:

   - **Correctness** — Does the solution actually solve the stated problem? Are there logical errors, wrong assumptions, or incorrect outputs?
   - **Completeness** — Are there gaps, missing edge cases, or unhandled scenarios? Does it cover everything the user asked for?
   - **Assumptions** — What was assumed that wasn't explicitly stated? Are those assumptions valid? List each assumption.
   - **Fragility** — Would this break under reasonable variations of the input or requirements? How brittle is it?
   - **Overconfidence check** — What would a skeptical senior engineer say about this? What's the most likely criticism?

3. **Identify at least one weakness** — Even if your confidence is high, you MUST identify at least one genuine concern, risk, or weakness. "No weaknesses" is never an acceptable answer.

4. **Calculate overall score** — Weighted average of dimensions. The overall score should reflect the weakest dimension — a chain is only as strong as its weakest link. A score of 100 should be virtually impossible.

5. **Write the session log entry** — Use the Write tool to append to `.confidence-loops/session.md` in the project root. Create the directory and file if they don't exist. Use this format:

   ```markdown
   ## Check #N — Post-task | YYYY-MM-DD HH:MM
   - **Score:** XX/100
   - **Summary:** [2-3 sentence summary of strengths and weaknesses]
   - **Suggestions:** [Only if score < 80: specific improvements proposed]
   ```

   Increment the check number based on existing entries in the file.

## Output Format

Present your assessment to the user in this format:

```
CONFIDENCE ASSESSMENT
═══════════════════════════════════════

Original task: [restate the task in one line]

Correctness:    XX/100 — [one-line justification]
Completeness:   XX/100 — [one-line justification]
Assumptions:    XX/100 — [one-line justification]
Fragility:      XX/100 — [one-line justification]

Overall Score:  XX/100

Strengths:
• [strength 1]
• [strength 2]

Weaknesses:
• [weakness 1 — REQUIRED, always at least one]
• [weakness 2 if applicable]

Skeptical Take: [What a skeptical senior engineer would say]
```

## If Score < 80

When the overall score is below 80, add a **Suggested Improvements** section:

```
Suggested Improvements:
1. [specific, actionable improvement]
2. [specific, actionable improvement]

Would you like me to implement these improvements?
```

**IMPORTANT:** Do NOT implement improvements automatically. Present them and wait for user approval.

## Rules

- Be genuinely critical, not performatively critical
- A score of 95+ should be rare and reserved for trivially simple, well-tested solutions
- Anchor your criticisms in specific, concrete concerns — not vague "could be better"
- If you realize your solution has a genuine flaw during assessment, say so clearly
- Never skip the session log write
