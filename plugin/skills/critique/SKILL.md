---
name: critique
description: Adversarial binary critique of code or plans.
---

# Devil's Advocate Critique

You are running an **adversarial binary critique**. Every criterion either passes or fails — no percentage scores, no wiggle room. You must be your own harshest critic.

## Target Detection

Determine whether you are critiquing **code** or a **plan** based on conversation context:
- If the user provides a path to a plan/design document, or you just wrote one → **plan critique** (22 criteria)
- If you just wrote code, or the user asks you to critique code changes → **code critique** (20 criteria)
- If unclear, ask the user

## Scope-Bounded Critique

**Critique ONLY what was requested.** Do not penalize for out-of-scope features. If a criterion doesn't apply to the target (e.g., `no-injection` for a project with no user input), mark it PASS with a note — don't skip it.

## Process

### Step 0: Independence Gate

**If you wrote or contributed to the target being critiqued (same conversation), you MUST dispatch an independent subagent.** Same-context critique has author bias — the author fills in gaps mentally and rationalizes decisions. Independent critique only sees the artifact and codebase.

**Dispatch pattern:** Before dispatching, replace `TARGET_PATH` with the actual file path or description of changes, and expand the criteria placeholder with the appropriate criteria block from Step 4 (code or plan).

```
Agent({
  description: "Independent DA critique",
  model: "opus",
  prompt: `You are a devil's advocate reviewer. Perform an adversarial binary critique of: TARGET_PATH

Read CLAUDE.md first for project conventions. Then read the target file. Then verify all claims against the actual codebase using Read, Grep, Glob, and Bash (npm list, tsc --noEmit, etc.).

CRITERIA_BLOCK

For each criterion: PASS with brief evidence, or FAIL with file:line and a Fix: suggestion.
Write results to .devils-advocate/logs/check-N-critique-YYYY-MM-DD-HHMM.md
Write session entry to .devils-advocate/session.md
Run: touch .devils-advocate/.commit-reviewed`
})
```

**When to run inline (without subagent):** Only when critiquing code or plans you did NOT write in this conversation (e.g., reviewing someone else's PR, auditing existing code).

**Fallback:** If the Agent tool is unavailable or dispatch fails, proceed with inline critique but prepend a warning: `WARNING: Self-critique — author bias may be present.`

### Step 0b: Context Gate

Before critiquing (whether inline or via subagent), verify you have sufficient context:
1. **Have you read the relevant files?** — If you haven't used Read/Grep to examine the actual code or plan, STOP.
2. **Do you understand the task?** — If the task was vague or you can't restate it precisely, STOP.
3. **Do you know the project structure?** — If you haven't explored the repo enough to understand how components connect, STOP.
4. **Is there something to critique?** — If the task was conversational with no code or plan output, say so.

If any check fails, output a **CONTEXT INSUFFICIENT** block:
```
CONTEXT INSUFFICIENT
═══════════════════════════════════════
Cannot provide a meaningful critique. Missing:
• [what's missing]
• [what's needed]

Action required:
1. [specific step]
2. [specific step]
```

Do NOT produce results without context. A critique with insufficient context is worse than no critique — it creates false confidence.

### Step 1: Discover project standards

Search for documented standards, architectural decisions, and existing patterns:

1. **Standards files** — Use Read to check for `CLAUDE.md` and `AGENTS.md` in the project root. Note any conventions, required patterns, or constraints they define.
2. **ADR files** — Use Glob to search for architectural decision records: `docs/adr/*.md`, `docs/decisions/*.md`, `adr/*.md`, `decisions/*.md`, `doc/architecture/decisions/*.md`, `**/ADR-*.md`. Read any that exist.
3. **Existing patterns** *(code mode only)* — Use Grep to search the codebase for utilities, helpers, or conventions similar to the code being critiqued. Look for patterns the work might be duplicating.
4. **Architectural domain** — Identify what layer, module, or service the change touches. Note which boundaries exist around it (API layers, service interfaces, module exports).
5. **Dominant patterns** — Grep for how similar operations are done elsewhere in the codebase. Find 3-5 examples of the same category of operation (DB access, API calls, event handling, etc.) and note the dominant pattern. If 5+ instances do it one way, that's the established pattern — violations FAIL even if undocumented.
6. **Boundary markers** — Look for barrel exports (`index.ts`/`index.js`), API client modules, repository patterns, service layers, or interface files that indicate intentional architectural boundaries.

**Important:** If standards files exist but contain no actionable conventions or constraints, treat it as if no standards were found.

Record what you find — standards violations should cause the relevant criteria to FAIL.

### Step 2: Identify the target

What is being critiqued? State it clearly. Note whether this is a code critique or plan critique.

### Step 3: Gather evidence

Before evaluating, collect concrete evidence:
- Use Read/Grep/Glob to examine the code or plan thoroughly
- **Code mode:** Search for test files, run tests with Bash, search for security patterns (hardcoded secrets, `eval()`, unsanitized input, SQL string concatenation, `innerHTML`, command injection vectors), check dependency manifests
- **Plan mode:** Verify referenced APIs exist, check dependency ordering, verify referenced files/packages exist
- Note specific file paths and line numbers for any issues

### Step 4: Evaluate against criteria

Run every criterion in the appropriate set. For each criterion:
- **PASS** — criterion is satisfied, with brief evidence
- **FAIL** — criterion is violated, with `file:line` evidence and a **Fix:** suggestion

Every FAIL must include a `Fix:` — a fail without a fix is useless.

#### Code Criteria (20 criteria, 8 dimensions)

```
Correctness:
  tests-pass        — Do all tests pass? (run them, don't assume)
  logic-correct     — Does the code do what it claims?
  edge-cases        — Are boundary conditions handled?

Security:
  no-secrets        — No hardcoded secrets, keys, or tokens?
  input-validated   — External input validated before use?
  no-injection      — No SQL injection, XSS, command injection vectors?
  auth-enforced     — Are authorization checks in place for protected operations?

Quality:
  no-dead-code      — No unused imports, unreachable code, commented-out blocks?
  no-placeholders   — No TODO/FIXME/stub that should be implemented?
  error-handling    — Errors caught and handled (not silently swallowed)?
  no-code-smell     — No god classes, feature envy, leaky abstractions, inappropriate intimacy, or data clumps?

Performance:
  no-obvious-perf   — No N+1 queries, O(n²) in hot paths, or unnecessary allocations?

Consistency:
  types-consistent  — Types match across the change?
  naming-matches    — Names follow project conventions?
  patterns-followed — Code follows established patterns in the codebase?

Integration:
  imports-correct   — All imports resolve to real files/packages?
  tests-exist       — New code has corresponding tests?
  no-regressions    — Existing tests still pass?

Architecture:
  boundaries-respected — Does the code respect established architectural boundaries (service layers, API boundaries, module interfaces)? Check: grep for how similar operations are done elsewhere. If a dominant pattern exists and this code bypasses it, FAIL.
  no-hacky-shortcuts   — Does the code solve the actual problem? FAIL if: symptom-fixing instead of root cause, special-case conditionals instead of proper abstractions, bypassing existing systems instead of extending them, duplicating code instead of extracting, string manipulation instead of proper parsing, or swallowing exceptions.
```

#### Plan Criteria (22 criteria, 10 dimensions)

```
Completeness:
  req-coverage       — Does the plan address every requirement it claims to?
  no-placeholders    — Are there any TODO/FIXME/stub/placeholder items that should be implemented?
  edge-cases         — Does the plan handle error states, empty inputs, and boundary conditions?

Correctness:
  api-verified       — Are all third-party library APIs verified against actual docs (not assumed)?
  patterns-correct   — Do code patterns match the library's documented usage?

Testability:
  tests-per-step     — Does each task include specific tests (not just "add tests")?
  verification       — Is there an E2E or integration verification strategy?

Security:
  no-secrets         — Are secrets handled via env vars/vault, never hardcoded?
  input-validated    — Is all external input validated (Zod schemas, parameterized queries)?
  auth-designed      — Does the plan address authorization for protected operations?

Consistency:
  types-consistent   — Are type definitions consistent across files and packages?
  naming-matches     — Do names follow the project's conventions?

Simplicity:
  no-overengineering — Is the plan doing only what's needed (no YAGNI violations)?
  no-reinvention     — Does the plan use established libraries for solved problems?

Dependencies:
  correct-order      — Are tasks ordered correctly (no step depends on a later step)?
  deps-available     — Are all referenced dependencies available (packages exist, APIs reachable)?

Resilience:
  rollback-plan      — Can changes be reversed if something goes wrong?
  perf-considered    — Does the plan account for performance at expected scale?

Integration:
  imports-correct    — Do import paths reference files/packages that actually exist?
  follows-patterns   — Does the plan follow the project's established patterns?

Architecture:
  boundaries-respected — Does the plan respect established architectural boundaries? Check: grep for how similar operations are done in the codebase. If the plan proposes bypassing a dominant pattern (e.g., direct DB access when an API layer exists), FAIL.
  no-hacky-shortcuts   — Does the plan solve the actual problem? FAIL if: band-aid fixes, workarounds that skip root cause, special-case handling instead of proper abstractions, or bypassing existing systems instead of extending them.
```

### Step 5: Write the session log entry

Read `.devils-advocate/session.md` first (if it exists), then use the Write tool to write the full existing contents plus your new entry appended at the end. Create the directory and file if they don't exist. Before writing, use Bash to run `git rev-parse --short HEAD` to get the current commit SHA. Use this format:

   ```markdown
   ## Check #N — Critique | YYYY-MM-DD HH:MM | <git-sha>
   - **Result:** X/Y PASS
   - **Failing:** [comma-separated list of failing criteria, or "none"]
   - **Summary:** [1-2 sentence summary]
   ```

   Increment the check number based on existing entries in the file.

After writing the session log entry, also write the full formatted critique output (everything from the Output Format section) to `.devils-advocate/logs/check-{N}-critique-{YYYY-MM-DD}-{HHMM}.md` using the same check number and timestamp. Create the `logs/` directory if it doesn't exist.

After writing both log files, run `touch .devils-advocate/.commit-reviewed` to signal that a critique has been performed. This allows the pre-commit hook to permit the next `git commit`.

## Output Format

```
DEVIL'S ADVOCATE CRITIQUE (Binary Eval)
═══════════════════════════════════════

Target: [plan filename or "code changes for <task>"]

  Correctness:
    tests-pass ...... PASS
    logic-correct ... FAIL — [specific issue with file:line]
                      Fix: [actionable fix]
    edge-cases ...... PASS

  Security:
    no-secrets ...... PASS
    input-validated . FAIL — String interpolation in buildQuery() at db.ts:45.
                      Fix: Use parameterized query builder.
    no-injection .... PASS
    auth-enforced ... PASS

  Architecture:
    boundaries-respected .. PASS
    no-hacky-shortcuts .... PASS

  [... remaining dimensions ...]

Result: 17/20 PASS — 3 criteria need fixing

Failing criteria with fixes:
1. logic-correct: [specific fix with file:line]
2. input-validated: [specific fix with file:line]
3. [...]

Unverified:
• [what you did NOT verify — MANDATORY, at least one item]
• [e.g., "I did not run the tests" / "I did not verify this compiles"]
```

## Rules

- Be genuinely critical, not performatively critical
- Every FAIL must cite `file:line` evidence and include a `Fix:` suggestion
- Every PASS should have brief evidence (not just "looks fine")
- Anchor your criticisms in specific, concrete concerns — not vague "could be better"
- If you realize the work has a genuine flaw during assessment, say so clearly
- Never skip the session log write
- The "Unverified" section is MANDATORY — must list at least one thing. If you claim you verified everything, you're lying.
