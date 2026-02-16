---
name: critique
description: Adversarial self-critique of the current solution. Triggers: "check confidence", "assess solution", "scrutinize this", "play devil's advocate".
---

# Devil's Advocate Critique

You are running an **adversarial self-critique** of your current work. You must be your own harshest critic. Do NOT rubber-stamp your own output.

## Scope-Bounded Critique

**Critique ONLY what was requested.** Do not assume features, methods, or functionality that were never part of the task or plan. Do not penalize the solution for lacking things that were never in scope. Exceptions:
- **Testing** — always evaluate whether tests exist and pass for the code that was written
- **Security** — always evaluate security concerns for the code that was written

If the task was "add a login form" do NOT critique the absence of a password reset flow, OAuth integration, or rate limiting unless those were explicitly part of the requirements. Critiquing out-of-scope concerns creates noise and erodes trust in the tool.

## Process

### Step 0: Context Gate

Before running a critique, verify you have sufficient context. Check:
1. **Have you read the relevant source files?** — If you haven't used Read/Grep to examine the actual code being critiqued, STOP.
2. **Do you understand the original task?** — If the task was vague or you can't restate it precisely, STOP.
3. **Do you know the project structure?** — If you haven't explored the repo enough to understand how components connect, STOP.
4. **Is there code to critique?** — If the task was conversational (questions, explanations) with no code output, say so.

If any check fails, output a **CONTEXT INSUFFICIENT** block instead of a critique:
```
CONTEXT INSUFFICIENT
═══════════════════════════════════════
Cannot provide a meaningful critique. Missing:
• [what's missing — e.g., "Have not read the implementation files"]
• [what's needed — e.g., "Run /devils-advocate:critique after I read src/auth.ts"]

Action required:
1. [specific step the user should take]
2. [specific step the user should take]
```

Do NOT produce scores without context. A critique with insufficient context is worse than no critique — it creates false confidence.

### Step 1: Identify the original task

What was the user's original request or problem? State it clearly.

### Step 2: Gather evidence

Before scoring, collect concrete evidence:
- Use Grep/Glob to search for test files related to the code under review
- If tests exist, run them with Bash and record the results
- Use Grep to search for security-relevant patterns: hardcoded secrets, `eval()`, unsanitized input, SQL string concatenation, `innerHTML`, command injection vectors
- Note specific file paths and line numbers for any issues found

### Step 3: Evaluate against dimensions

Score each 0-100. **Every score MUST cite specific code references (`file:line`) as evidence.** Scores without evidence are not permitted — "Fragility: 65" is invalid, "Fragility: 65 — no null check at `auth.ts:47`, no test covers empty input" is valid.

   - **Correctness** — Does the solution actually solve the stated problem? Are there logical errors, wrong assumptions, or incorrect outputs?
   - **Completeness** — Are there gaps, missing edge cases, or unhandled scenarios? Does it cover everything the user asked for?
   - **Assumptions** — What was assumed that wasn't explicitly stated? Are those assumptions valid? List each assumption.
   - **Fragility** — Would this break under reasonable variations of the input or requirements? How brittle is it?
   - **Security** — Check for injection vectors (SQL, XSS, command), auth/authz issues, secrets/credentials in code, OWASP top 10 concerns. Use Grep to search for patterns like hardcoded secrets, unsanitized input, eval(), etc.
   - **Testing** — Do tests exist? Run them if so. What code paths lack coverage? Are there integration tests? Score 0 if no tests exist for the code that was written.
   - **Architecture** — Separation of concerns, coupling between modules, scalability implications, operational concerns (monitoring, rollback, deployment), API contract stability.
   - **Overconfidence check** — What would a skeptical senior engineer say about this? What's the most likely criticism?

### Step 4: Identify at least one weakness

Even if your confidence is high, you MUST identify at least one genuine concern, risk, or weakness. "No weaknesses" is never an acceptable answer.

### Step 5: Calculate overall score

Weighted average of dimensions. The overall score should reflect the weakest dimension — a chain is only as strong as its weakest link. A score of 100 should be virtually impossible.

### Step 6: Write the session log entry

Use the Write tool to append to `.devils-advocate/session.md` in the project root. Create the directory and file if they don't exist. Before writing, use Bash to run `git rev-parse --short HEAD` to get the current commit SHA. Use this format:

   ```markdown
   ## Check #N — Post-task | YYYY-MM-DD HH:MM | <git-sha>
   - **Score:** XX/100
   - **Summary:** [2-3 sentence summary of strengths and weaknesses]
   - **Suggestions:** [Only if score < 80: specific improvements proposed]
   ```

   Increment the check number based on existing entries in the file.

## Output Format

Present your assessment to the user in this format:

```
DEVIL'S ADVOCATE CRITIQUE
═══════════════════════════════════════

Original task: [restate the task in one line]

Correctness:    XX/100 — [justification with file:line evidence]
Completeness:   XX/100 — [justification with file:line evidence]
Assumptions:    XX/100 — [justification with file:line evidence]
Fragility:      XX/100 — [justification with file:line evidence]
Security:       XX/100 — [justification with file:line evidence]
Testing:        XX/100 — [justification with file:line evidence]
Architecture:   XX/100 — [justification with file:line evidence]

Overall Score:  XX/100

Strengths:
• [strength 1]
• [strength 2]

Weaknesses:
• [weakness 1 — REQUIRED, always at least one]
• [weakness 2 if applicable]

Skeptical Take: [What a skeptical senior engineer would say]

Unverified:
• [what you did NOT verify — MANDATORY, at least one item]
• [e.g., "I did not run the tests" / "I did not verify this compiles"]
• [e.g., "I cannot check runtime behavior" / "I did not review files X, Y, Z"]
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
- The "Unverified" section is MANDATORY — must list at least one thing. If you claim you verified everything, you're lying.
