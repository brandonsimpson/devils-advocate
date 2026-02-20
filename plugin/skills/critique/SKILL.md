---
name: critique
description: Adversarial self-critique of the current solution.
---

# Devil's Advocate Critique

You are running an **adversarial self-critique** of your current work. You must be your own harshest critic. Do NOT rubber-stamp your own output.

## Scope-Bounded Critique

**Critique ONLY what was requested.** Do not assume features, methods, or functionality that were never part of the task or plan. Do not penalize the solution for lacking things that were never in scope. Exceptions:
- **Testing** — always evaluate whether tests exist and pass for the code that was written
- **Security** — always evaluate security concerns for the code that was written
- **Standards Compliance** — always evaluate when project standards files exist (only scored when standards are found; omitted entirely otherwise)

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

### Step 1: Discover project standards

Search for documented standards, architectural decisions, and existing patterns:

1. **Standards files** — Use Read to check for `CLAUDE.md` and `AGENTS.md` in the project root. Note any conventions, required patterns, or constraints they define.
2. **ADR files** — Use Glob to search for architectural decision records: `docs/adr/*.md`, `docs/decisions/*.md`, `adr/*.md`, `decisions/*.md`, `doc/architecture/decisions/*.md`, `**/ADR-*.md`. Read any that exist.
3. **Existing patterns** — Use Grep to search the codebase for utilities, helpers, or conventions similar to the code being critiqued. Look for patterns the work might be duplicating.
4. **Project maturity check** — If no ADR files are found, run `git rev-list --count HEAD` to check the commit count. Projects with 50+ commits but no ADRs may benefit from an advisory.

**Important:** If standards files exist but contain no actionable conventions or constraints (e.g., only a project description), treat it as if no standards were found — do not score Standards Compliance against a file with no actual standards.

Record what you find — it feeds into the Standards Compliance dimension and the Existing Patterns output section.

### Step 2: Identify the original task

What was the user's original request or problem? State it clearly.

### Step 3: Gather evidence

Before scoring, collect concrete evidence:
- Use Grep/Glob to search for test files related to the code under review
- If tests exist, run them with Bash and record the results
- Use Grep to search for security-relevant patterns: hardcoded secrets, `eval()`, unsanitized input, SQL string concatenation, `innerHTML`, command injection vectors
- Note specific file paths and line numbers for any issues found
- **Reinvention check** — Evaluate whether the code builds a custom implementation of something that has well-established, battle-tested solutions. This is especially critical in domains where getting it wrong has severe consequences:
  - **Cryptography** — custom hashing, encryption, token generation, random number generation
  - **Authentication/authorization** — hand-rolled session management, JWT handling, OAuth flows, password storage
  - **Input sanitization** — custom HTML/SQL escaping instead of parameterized queries or established sanitization libraries
  - **Date/time handling** — manual timezone math, custom date parsing
  - **HTTP clients** — custom retry/backoff logic, connection pooling
  - **Data validation** — hand-written schema validation instead of established validators

  Check `package.json`, `requirements.txt`, `go.mod`, `Cargo.toml`, or equivalent for whether established libraries for the problem domain are already available or already in use elsewhere in the project. If the code reinvents a solved problem, flag it — even if the implementation is technically correct, because correctness today doesn't guarantee correctness against future edge cases that battle-tested libraries have already encountered.

### Step 4: Evaluate against dimensions

Score each 0-100. **Every score MUST cite specific code references (`file:line`) as evidence.** Scores without evidence are not permitted — "Fragility: 65" is invalid, "Fragility: 65 — no null check at `auth.ts:47`, no test covers empty input" is valid.

Calibration anchors — use these to avoid compressing all scores into 70-85:
- **0-30:** Fundamentally broken — does not work, critical security flaw, or completely wrong approach
- **31-50:** Significant issues — partially works but has major gaps, missing error handling, or serious design flaws
- **51-70:** Functional but concerning — works for the happy path but has notable weaknesses, missing tests, or fragile assumptions
- **71-85:** Solid with minor issues — works correctly, reasonable design, but has room for improvement
- **86-95:** Very good — well-tested, well-designed, handles edge cases, only minor nits
- **96-100:** Virtually never awarded — reserved for trivially simple, comprehensively tested, flawless implementations

   - **Correctness** — Does the solution actually solve the stated problem? Are there logical errors, wrong assumptions, or incorrect outputs?
   - **Completeness** — Are there gaps, missing edge cases, or unhandled scenarios? Does it cover everything the user asked for?
   - **Assumptions** — What was assumed that wasn't explicitly stated? Are those assumptions valid? List each assumption.
   - **Fragility** — Would this break under reasonable variations of the input or requirements? How brittle is it?
   - **Security** — Check for injection vectors (SQL, XSS, command), auth/authz issues, secrets/credentials in code, OWASP top 10 concerns. Use Grep to search for patterns like hardcoded secrets, unsanitized input, eval(), etc.
   - **Testing** — Do tests exist? Run them if so. What code paths lack coverage? Are there integration tests? Score 0 if no tests exist for the code that was written. For prompt-only or documentation-only projects with no executable code, evaluate whether structural validation exists (schema validation, linting, consistency checks) instead of traditional tests — score against whatever validation mechanism is appropriate for the project type.
   - **Architecture** — Separation of concerns, coupling between modules, scalability implications, operational concerns (monitoring, rollback, deployment), API contract stability.
   - **Standards Compliance** *(conditional — only score this if Step 1 found standards files or ADRs)* — Does the code follow conventions documented in `CLAUDE.md`, `AGENTS.md`, or ADRs? Evidence must cite both the standard (e.g., `CLAUDE.md`, `ADR-003`) and the drifting code (`file:line`). Distinguish between intentional drift (acknowledged deviation with rationale) and accidental drift (convention ignored or unknown). Omit this dimension entirely if no standards were found.
   - **Overconfidence check** — What would a skeptical senior engineer say about this? What's the most likely criticism?

### Step 5: Identify at least one weakness

Even if your confidence is high, you MUST identify at least one genuine concern, risk, or weakness. "No weaknesses" is never an acceptable answer.

### Step 6: Calculate overall score

Calculate the overall score as follows: take the average of all scored dimensions, then pull it toward the lowest-scoring dimension. Specifically: `overall = (average + lowest) / 2` (include Standards Compliance if it was scored). This ensures a single weak dimension drags down the overall score — a chain is only as strong as its weakest link — while still rewarding strength across other dimensions. A score of 100 should be virtually impossible.

### Step 7: Write the session log entry

Read `.devils-advocate/session.md` first (if it exists), then use the Write tool to write the full existing contents plus your new entry appended at the end. Create the directory and file if they don't exist. Before writing, use Bash to run `git rev-parse --short HEAD` to get the current commit SHA. Use this format:

   ```markdown
   ## Check #N — Post-task | YYYY-MM-DD HH:MM | <git-sha>
   - **Score:** XX/100
   - **Summary:** [2-3 sentence summary of strengths and weaknesses]
   - **Suggestions:** [Only if score < 80: specific improvements proposed]
   ```

   Increment the check number based on existing entries in the file.

After writing the session log entry, also write the full formatted critique output (everything from the Output Format section) to `.devils-advocate/logs/check-{N}-critique-{YYYY-MM-DD}-{HHMM}.md` using the same check number and timestamp. Create the `logs/` directory if it doesn't exist.

After writing both log files, run `touch .devils-advocate/.commit-reviewed` to signal that a critique has been performed. This allows the pre-commit hook to permit the next `git commit`.

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
Standards:      XX/100 — [if standards files found; omit line entirely if not]

Overall Score:  XX/100

Standards Drift: [only if Standards was scored]
• [standard] → [drifting code at file:line] — [intentional/accidental]

Existing Patterns: [only if duplicated patterns found in codebase]
• [pattern at file:line] — [how the current work duplicates it]

Reinvention Risk: [only if custom implementations of solved problems found]
• [file:line] — [what is being hand-rolled] → [established solution that should be used instead]

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

Advisory: [only if no ADRs found in project with 50+ commits]
This project has XX commits but no architectural decision records.
Consider adopting ADRs to document key decisions.
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
