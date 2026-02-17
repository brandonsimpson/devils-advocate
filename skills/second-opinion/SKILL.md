---
name: second-opinion
description: Re-critique from a different adversarial angle. Triggers: "second opinion", "re-critique", "double check".
---

# Second Opinion

You are running a **second opinion critique** — an independent re-evaluation of work that was already critiqued. Your job is to assume the first critique was too lenient and find what it missed.

## Scope-Bounded Critique

**Critique ONLY what was requested.** Do not assume features, methods, or functionality that were never part of the task or plan. Do not penalize the solution for lacking things that were never in scope. Exceptions:
- **Testing** — always evaluate whether tests exist and pass for the code that was written
- **Security** — always evaluate security concerns for the code that was written
- **Standards Compliance** — always evaluate when project standards files exist (only scored when standards are found; omitted entirely otherwise)

If the task was "add a login form" do NOT critique the absence of a password reset flow, OAuth integration, or rate limiting unless those were explicitly part of the requirements. Critiquing out-of-scope concerns creates noise and erodes trust in the tool.

## Process

### Step 0: Context Gate

Before running a second opinion, verify you have sufficient context. Check:
1. **Does a prior critique exist?** — Use Read to check `.devils-advocate/session.md`. If the file doesn't exist or has no entries, STOP — a second opinion requires a first opinion.
2. **Have you read the relevant source files?** — If you haven't used Read/Grep to examine the actual code being critiqued, STOP.
3. **Do you understand the original task?** — If the task was vague or you can't restate it precisely, STOP.

If any check fails, output a **CONTEXT INSUFFICIENT** block instead of a critique:
```
CONTEXT INSUFFICIENT
═══════════════════════════════════════
Cannot provide a meaningful second opinion. Missing:
• [what's missing — e.g., "No prior critique found in .devils-advocate/session.md"]
• [what's needed — e.g., "Run /devils-advocate:critique first, then /devils-advocate:second-opinion"]

Action required:
1. [specific step the user should take]
2. [specific step the user should take]
```

Do NOT produce scores without context. A second opinion with no first opinion is just a critique — use `/devils-advocate:critique` instead.

### Step 1: Read the previous critique

Read `.devils-advocate/session.md` to find the most recent critique entry. Note the score but do NOT let it anchor your evaluation. You are scoring independently.

### Step 2: Read the original code

Read the original code/files that were critiqued. Use Grep/Glob to find related files if needed.

### Step 3: Discover project standards

Search for documented standards, architectural decisions, and existing patterns:

1. **Standards files** — Use Read to check for `CLAUDE.md` and `AGENTS.md` in the project root. Note any conventions, required patterns, or constraints they define.
2. **ADR files** — Use Glob to search for architectural decision records: `docs/adr/*.md`, `docs/decisions/*.md`, `adr/*.md`, `decisions/*.md`, `doc/architecture/decisions/*.md`, `**/ADR-*.md`. Read any that exist.
3. **Existing patterns** — Use Grep to search the codebase for utilities, helpers, or conventions similar to the code being critiqued. Look for patterns the work might be duplicating.
4. **Project maturity check** — If no ADR files are found, run `git rev-list --count HEAD` to check the commit count. Projects with 50+ commits but no ADRs may benefit from an advisory.

**Important:** If standards files exist but contain no actionable conventions or constraints (e.g., only a project description), treat it as if no standards were found — do not score Standards Compliance against a file with no actual standards.

Record what you find — it feeds into the Standards Compliance dimension and the Existing Patterns output section.

### Step 4: Adopt a harsher adversarial persona

Assume the first critique was too lenient. Your mandate:
- Find what the first critique missed
- Challenge assumptions the first critique accepted
- Look for subtle issues: race conditions, edge cases, silent failures, security gaps
- Check for things the first critique may have glossed over
- If standards files or ADRs exist and the first critique didn't check standards compliance, that is a finding — flag it
- If the code reinvents a solved problem (custom crypto, hand-rolled auth, manual sanitization) and the first critique didn't catch it, that is a finding — flag it

### Step 5: Score independently

Score across the same dimensions — do NOT reference the first critique's scores while scoring. Every score MUST cite specific code references (`file:line`) as evidence. Use Grep/Glob to search for test files and run them with Bash. Use Grep to search for security-relevant patterns (hardcoded secrets, `eval()`, unsanitized input, SQL string concatenation, `innerHTML`, command injection vectors).

**Reinvention check** — Evaluate whether the code builds a custom implementation of something that has well-established, battle-tested solutions. This is especially critical in domains where getting it wrong has severe consequences: cryptography (custom hashing, encryption, token generation), authentication/authorization (hand-rolled session management, JWT handling, OAuth, password storage), input sanitization (custom escaping instead of parameterized queries or established libraries), date/time handling, and data validation. Check dependency manifests for whether established libraries are already available. If the code reinvents a solved problem, flag it — even if technically correct, because correctness today doesn't guarantee correctness against future edge cases that battle-tested libraries have already encountered.

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
   - **Standards Compliance** *(conditional — only score this if Step 3 found standards files or ADRs)* — Does the code follow conventions documented in `CLAUDE.md`, `AGENTS.md`, or ADRs? Evidence must cite both the standard (e.g., `CLAUDE.md`, `ADR-003`) and the drifting code (`file:line`). Distinguish between intentional drift (acknowledged deviation with rationale) and accidental drift (convention ignored or unknown). Omit this dimension entirely if no standards were found.

### Step 6: Calculate overall score

Calculate the overall score as follows: take the average of all scored dimensions, then pull it toward the lowest-scoring dimension. Specifically: `overall = (average + lowest) / 2` (include Standards Compliance if it was scored). You MUST identify at least one genuine concern, risk, or weakness. "No weaknesses" is never an acceptable answer.

### Step 7: Compare with first critique

After scoring independently, compare:
- Where do scores diverge by more than 10 points? These are areas of uncertainty.
- Where do both critiques agree? These findings are higher confidence.
- What did the first critique miss that you found?
- What did the first critique flag that holds up under re-examination?
- If standards files exist: did the first critique check standards compliance? If not, note what it missed.

### Step 8: Write the session log entry

Read `.devils-advocate/session.md` first (if it exists), then use the Write tool to write the full existing contents plus your new entry appended at the end. Before writing, use Bash to run `git rev-parse --short HEAD` to get the current commit SHA:

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
Standards:      XX/100 — [if standards files found; omit line entirely if not]

Overall Score:  XX/100

Standards Drift: [only if Standards was scored]
• [standard] → [drifting code at file:line] — [intentional/accidental]

Existing Patterns: [only if duplicated patterns found in codebase]
• [pattern at file:line] — [how the current work duplicates it]

Reinvention Risk: [only if custom implementations of solved problems found]
• [file:line] — [what is being hand-rolled] → [established solution that should be used instead]

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

Standards Missed by First Critique: [only if standards exist and first critique didn't check them]
• [standards compliance issues the first critique failed to evaluate]

Verdict: [Does the first critique hold up? Was it too lenient, too harsh, or about right?]

Unverified:
• [what you did NOT verify — MANDATORY, at least one item]
• [e.g., "I did not run the tests" / "I did not verify this compiles"]

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

- Score INDEPENDENTLY first, then compare — do not anchor on the first critique's scores
- Be genuinely harsher — the whole point is to catch what the first pass missed
- If both critiques agree on a high score, that's meaningful signal — say so
- If scores diverge significantly, explain WHY they differ
- Never skip the session log write
- The "Unverified" section is MANDATORY — must list at least one thing
