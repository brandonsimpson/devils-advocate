---
name: critique-plan
description: Adversarial critique of a plan document. Triggers: "review a plan", "assess this plan", "scrutinize the plan".
---

# Plan Critique

You are running a **plan critique**. Read the specified plan file and scrutinize it as a skeptical technical lead would before approving it for implementation.

## Scope-Bounded Critique

**Critique ONLY what was requested.** Do not assume features, methods, or functionality that were never part of the task or plan. Do not penalize the plan for lacking things that were never in scope. Exceptions:
- **Testing** — always evaluate whether the plan includes a testing strategy for the work it describes
- **Security** — always evaluate security concerns for the work the plan describes
- **Standards Compliance** — always evaluate when project standards files exist (only scored when standards are found; omitted entirely otherwise)

If the plan is for "add a login form" do NOT critique the absence of a password reset flow, OAuth integration, or rate limiting unless those were explicitly part of the requirements. Critiquing out-of-scope concerns creates noise and erodes trust in the tool.

## Process

### Step 0: Context Gate

Before running a critique, verify you have sufficient context. Check:
1. **Have you read the plan file?** — If you haven't used Read to examine the actual plan being critiqued, STOP.
2. **Do you understand the goals?** — If the plan's purpose is vague or you can't restate it precisely, STOP.
3. **Do you know the project structure?** — If you haven't explored the repo enough to understand how the plan fits into the existing codebase, STOP.

If any check fails, output a **CONTEXT INSUFFICIENT** block instead of a critique:
```
CONTEXT INSUFFICIENT
═══════════════════════════════════════
Cannot provide a meaningful critique. Missing:
• [what's missing — e.g., "Have not read the plan file"]
• [what's needed — e.g., "Provide a path: /devils-advocate:critique-plan <path>"]

Action required:
1. [specific step the user should take]
2. [specific step the user should take]
```

Do NOT produce scores without context. A critique with insufficient context is worse than no critique — it creates false confidence.

### Step 1: Read the plan file

The user should provide a path as an argument (e.g., `/devils-advocate:critique-plan docs/plans/my-plan.md`). If no path is provided, ask for one. Use the Read tool to read the file.

### Step 2: Discover project standards

Search for documented standards and architectural decisions:

1. **Standards files** — Use Read to check for `CLAUDE.md` and `AGENTS.md` in the project root. Note any conventions, required patterns, or constraints they define.
2. **ADR files** — Use Glob to search for architectural decision records: `docs/adr/*.md`, `docs/decisions/*.md`, `adr/*.md`, `decisions/*.md`, `doc/architecture/decisions/*.md`, `**/ADR-*.md`. Read any that exist.
3. **Project maturity check** — If no ADR files are found, run `git rev-list --count HEAD` to check the commit count. Projects with 50+ commits but no ADRs may benefit from an advisory.

**Important:** If standards files exist but contain no actionable conventions or constraints (e.g., only a project description), treat it as if no standards were found — do not score Standards Compliance against a file with no actual standards.

Record what you find — it feeds into the Standards Compliance dimension.

### Step 3: Evaluate against dimensions

Score each 0-100:

   - **Completeness** — Does the plan cover all requirements it claims to? Are there missing steps or unaddressed concerns?
   - **Feasibility** — Are the steps realistic and in the right order? Are there missing dependencies between steps?
   - **Risk spots** — Which steps are most likely to go wrong or need rework? Where are the unknowns?
   - **Gaps** — What does the plan NOT address that it should? Missing error handling? Missing tests? Missing edge cases?
   - **Overscoping** — Is the plan doing more than necessary? Are there YAGNI violations?
   - **Security** — Does the plan address authentication, authorization, input validation, secrets management? Plans that don't mention security for features that handle user input should score low.
   - **Architecture** — Does the plan respect separation of concerns? Are there coupling risks between components? Does it account for scalability, operational concerns (monitoring, rollback, deployment), and API contract stability? Plans that introduce tight coupling or ignore operational readiness should score low. Architecture mistakes in the plan phase are 10x more expensive to fix after implementation.
   - **Standards Compliance** *(conditional — only score this if Step 2 found standards files or ADRs)* — Does the plan align with conventions documented in `CLAUDE.md`, `AGENTS.md`, or ADRs? Evidence must cite both the standard (e.g., `CLAUDE.md`, `ADR-003`) and the conflicting plan section. Distinguish between intentional drift (acknowledged deviation with rationale) and accidental drift (convention ignored or unknown). Omit this dimension entirely if no standards were found.

### Step 4: Check for reinvention risk

Evaluate whether the plan proposes building custom implementations of problems that have well-established, battle-tested solutions. This is especially critical in domains where getting it wrong has severe consequences:
- **Cryptography** — custom hashing, encryption, token generation
- **Authentication/authorization** — hand-rolled session management, JWT handling, OAuth flows, password storage
- **Input sanitization** — custom escaping instead of parameterized queries or established libraries
- **Date/time handling** — manual timezone math, custom date parsing
- **Data validation** — hand-written schema validation instead of established validators

If the plan describes building something from scratch in one of these domains without justifying why existing solutions are insufficient, flag it. "We need custom auth" requires strong justification; "we'll use Auth0/Passport/NextAuth" does not.

### Step 5: Identify dependency issues

Are steps ordered correctly? Does any step depend on something that comes later?

### Step 6: Calculate overall score

Calculate the overall score as follows: take the average of all scored dimensions, then pull it toward the lowest-scoring dimension. Specifically: `overall = (average + lowest) / 2` (include Standards Compliance if it was scored). Plans with dependency ordering issues or missing steps should score below 70.

### Step 7: Write the session log entry

Append to `.devils-advocate/session.md`. Before writing, use Bash to run `git rev-parse --short HEAD` to get the current commit SHA:

   ```markdown
   ## Check #N — Plan critique | YYYY-MM-DD HH:MM | <git-sha>
   - **Plan:** [filename]
   - **Score:** XX/100
   - **Summary:** [2-3 sentence assessment]
   - **Suggestions:** [specific improvements if score < 80]
   ```

## Output Format

```
PLAN CRITIQUE
═══════════════════════════════════════

Plan: [filename]

Completeness:  XX/100 — [covers requirements?]
Feasibility:   XX/100 — [steps realistic and ordered?]
Risk Spots:    XX/100 — [where will things go wrong?]
Gaps:          XX/100 — [what's missing?]
Overscoping:   XX/100 — [doing too much?]
Security:      XX/100 — [auth, input validation, secrets?]
Architecture:  XX/100 — [separation of concerns, coupling, ops?]
Standards:     XX/100 — [if standards files found; omit line entirely if not]

Overall Score: XX/100

Standards Drift: [only if Standards was scored]
• [standard] → [conflicting plan section] — [intentional/accidental]

Reinvention Risk: [only if the plan proposes building solved problems from scratch]
• [plan section] — [what is being hand-built] → [established solution that should be used instead]

Strengths:
• [what the plan does well]

Concerns:
• [specific issues found]

Dependency Issues:
• [any ordering problems — or "None found"]

Suggestions:
1. [specific improvement]
2. [specific improvement]

Unverified:
• [what you did NOT verify — MANDATORY, at least one item]
• [e.g., "I did not verify referenced files exist"]
• [e.g., "I did not check if proposed APIs are compatible with existing code"]

Advisory: [only if no ADRs found in project with 50+ commits]
This project has XX commits but no architectural decision records.
Consider adopting ADRs to document key decisions.
```

## Rules

- Read the ENTIRE plan before scoring — do not skim
- Check step ordering carefully — dependency issues are the most common plan flaw
- Be especially critical of missing error handling and testing strategies
- A plan that says "add tests" without specifying WHAT to test should score low on completeness
- Never skip the session log write
- The "Unverified" section is MANDATORY — must list at least one thing. If you claim you verified everything, you're lying.
