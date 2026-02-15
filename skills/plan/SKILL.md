---
name: plan
description: Use when the user asks to "review a plan", "check plan confidence", "assess this plan", "scrutinize the plan", "evaluate implementation plan", or invokes /devils-advocate:plan. Provides adversarial review of a plan document.
---

# Plan Review

You are running a **plan review**. Read the specified plan file and scrutinize it as a skeptical technical lead would before approving it for implementation.

## Process

1. **Read the plan file** — The user should provide a path as an argument (e.g., `/devils-advocate:plan docs/plans/my-plan.md`). If no path is provided, ask for one. Use the Read tool to read the file.

2. **Evaluate against these dimensions** — Score each 0-100:

   - **Completeness** — Does the plan cover all requirements it claims to? Are there missing steps or unaddressed concerns?
   - **Feasibility** — Are the steps realistic and in the right order? Are there missing dependencies between steps?
   - **Risk spots** — Which steps are most likely to go wrong or need rework? Where are the unknowns?
   - **Gaps** — What does the plan NOT address that it should? Missing error handling? Missing tests? Missing edge cases?
   - **Overscoping** — Is the plan doing more than necessary? Are there YAGNI violations?

3. **Identify dependency issues** — Are steps ordered correctly? Does any step depend on something that comes later?

4. **Calculate overall score** — Conservative weighted average. Plans with dependency ordering issues or missing steps should score below 70.

5. **Write the session log entry** — Append to `.devils-advocate/session.md`:

   ```markdown
   ## Check #N — Plan review | YYYY-MM-DD HH:MM
   - **Plan:** [filename]
   - **Score:** XX/100
   - **Summary:** [2-3 sentence assessment]
   - **Suggestions:** [specific improvements if score < 80]
   ```

## Output Format

```
PLAN REVIEW
═══════════════════════════════════════

Plan: [filename]

Completeness:  XX/100 — [covers requirements?]
Feasibility:   XX/100 — [steps realistic and ordered?]
Risk Spots:    XX/100 — [where will things go wrong?]
Gaps:          XX/100 — [what's missing?]
Overscoping:   XX/100 — [doing too much?]

Overall Score: XX/100

Strengths:
• [what the plan does well]

Concerns:
• [specific issues found]

Dependency Issues:
• [any ordering problems — or "None found"]

Suggestions:
1. [specific improvement]
2. [specific improvement]
```

## Rules

- Read the ENTIRE plan before scoring — do not skim
- Check step ordering carefully — dependency issues are the most common plan flaw
- Be especially critical of missing error handling and testing strategies
- A plan that says "add tests" without specifying WHAT to test should score low on completeness
- Never skip the session log write
