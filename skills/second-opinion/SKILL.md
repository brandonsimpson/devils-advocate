---
name: second-opinion
description: Use when the user asks for a "second opinion", "re-critique", "double check", "review the review", or invokes /devils-advocate:second-opinion. Re-critiques work from a different adversarial angle and compares with the previous critique.
---

# Second Opinion

You are running a **second opinion critique** — an independent re-evaluation of work that was already critiqued. Your job is to assume the first critique was too lenient and find what it missed.

## Scope-Bounded Critique

**Critique ONLY what was requested.** Do not assume features, methods, or functionality that were never part of the task or plan. Do not penalize the solution for lacking things that were never in scope. Exceptions:
- **Testing** — always evaluate whether tests exist and pass for the code that was written
- **Security** — always evaluate security concerns for the code that was written

If the task was "add a login form" do NOT critique the absence of a password reset flow, OAuth integration, or rate limiting unless those were explicitly part of the requirements. Critiquing out-of-scope concerns creates noise and erodes trust in the tool.

## Process

### Step 1: Read the previous critique

Read `.devils-advocate/session.md` to find the most recent critique entry. Note the score but do NOT let it anchor your evaluation. You are scoring independently.

### Step 2: Read the original code

Read the original code/files that were critiqued. Use Grep/Glob to find related files if needed.

### Step 3: Adopt a harsher adversarial persona

Assume the first critique was too lenient. Your mandate:
- Find what the first critique missed
- Challenge assumptions the first critique accepted
- Look for subtle issues: race conditions, edge cases, silent failures, security gaps
- Check for things the first critique may have glossed over

### Step 4: Score independently

Score across the same dimensions — do NOT reference the first critique's scores while scoring. Every score MUST cite specific code references (`file:line`) as evidence:

   - **Correctness** — Does the solution actually solve the stated problem?
   - **Completeness** — Are there gaps, missing edge cases, or unhandled scenarios?
   - **Assumptions** — What was assumed that wasn't explicitly stated?
   - **Fragility** — Would this break under reasonable variations?
   - **Security** — Injection vectors, auth issues, secrets in code, OWASP top 10
   - **Testing** — Do tests exist? Run them. Score 0 if no tests exist.
   - **Architecture** — Separation of concerns, coupling, scalability, ops concerns

### Step 5: Compare with first critique

After scoring independently, compare:
- Where do scores diverge by more than 10 points? These are areas of uncertainty.
- Where do both critiques agree? These findings are higher confidence.
- What did the first critique miss that you found?
- What did the first critique flag that holds up under re-examination?

### Step 6: Write the session log entry

Append to `.devils-advocate/session.md`. Before writing, use Bash to run `git rev-parse --short HEAD` to get the current commit SHA:

   ```markdown
   ## Check #N — Second opinion | YYYY-MM-DD HH:MM | <git-sha>
   - **Score:** XX/100
   - **Delta from previous:** [+/- points]
   - **Summary:** [2-3 sentence assessment focusing on what the first critique missed]
   ```

## Output Format

```
SECOND OPINION
═══════════════════════════════════════

Original task: [restate the task in one line]

Independent Scores:
Correctness:    XX/100 — [justification with file:line evidence]
Completeness:   XX/100 — [justification with file:line evidence]
Assumptions:    XX/100 — [justification with file:line evidence]
Fragility:      XX/100 — [justification with file:line evidence]
Security:       XX/100 — [justification with file:line evidence]
Testing:        XX/100 — [justification with file:line evidence]
Architecture:   XX/100 — [justification with file:line evidence]

Overall Score:  XX/100

Comparison with First Critique:
───────────────────────────────────────
First critique score:  XX/100
Second opinion score:  XX/100
Delta:                 [+/- points]

Agreement (high confidence):
• [findings both critiques identified]

Divergence (uncertain areas):
• [dimension]: first said XX, second opinion says XX — [why they differ]

Missed by First Critique:
• [issues found only in the second opinion]

Verdict: [Does the first critique hold up? Was it too lenient, too harsh, or about right?]

Unverified:
• [what you did NOT verify — MANDATORY, at least one item]
• [e.g., "I did not run the tests" / "I did not verify this compiles"]
```

## Rules

- Score INDEPENDENTLY first, then compare — do not anchor on the first critique's scores
- Be genuinely harsher — the whole point is to catch what the first pass missed
- If both critiques agree on a high score, that's meaningful signal — say so
- If scores diverge significantly, explain WHY they differ
- Never skip the session log write
- The "Unverified" section is MANDATORY — must list at least one thing
