<p align="center">
  <img src="banner.png" alt="Devil's Advocate" width="100%">
</p>

# devils-advocate

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin that adds adversarial self-critique to every task. Claude scores its own work across multiple dimensions, identifies weaknesses, and proposes improvements — before you ship anything.

## Why

LLMs confidently produce wrong answers. They never hesitate, never hedge, and present fabricated information with the same authority as accurate responses. This plugin was inspired by the ideas in [Confidently Wrong](https://brandon.cc/confidently-wrong) — it builds intentional friction and formalized skepticism directly into the AI-assisted development workflow.

This plugin forces Claude to argue against its own output, score its confidence, and surface concerns before you act on a response. A score of 100 is virtually impossible, and "no weaknesses found" is never accepted.

## Install

### Via plugin marketplace (recommended)

In Claude Code, add the marketplace and install:

```
/plugin marketplace add brandonsimpson/devils-advocate
/plugin install devils-advocate@devils-advocate
```

### Manual install

Clone the repo:

```bash
git clone https://github.com/brandonsimpson/devils-advocate.git ~/.claude/plugins/devils-advocate
```

Then add it to your Claude Code settings (`~/.claude/settings.json`):

```json
{
  "plugins": [
    "~/.claude/plugins/devils-advocate"
  ]
}
```

Or install for a single session:

```bash
claude --plugin-dir ~/.claude/plugins/devils-advocate
```

## Commands

### `/devils-advocate:critique`

Post-task adversarial critique. Scores the current solution across seven dimensions (plus a conditional eighth):

- **Correctness** — Does it actually solve the problem?
- **Completeness** — Missing edge cases or gaps?
- **Assumptions** — What was assumed that wasn't stated?
- **Fragility** — Would it break under reasonable input variations?
- **Security** — Injection vectors, auth/authz issues, secrets in code, OWASP top 10
- **Testing** — Do tests exist? Do they pass? What code paths lack coverage?
- **Architecture** — Separation of concerns, coupling, scalability, operational readiness
- **Standards Compliance** *(conditional)* — Does the code follow conventions documented in `CLAUDE.md`, `AGENTS.md`, or ADRs? Only scored when standards files exist; omitted entirely otherwise. Distinguishes intentional vs accidental drift.

Before scoring, the skill discovers project standards by reading `CLAUDE.md`/`AGENTS.md`, searching for ADR files, and grepping for existing patterns the code might be duplicating.

Every score must cite specific code references (`file:line`) as evidence. Scores without evidence are not permitted. Scores are calibrated against explicit anchors (0-30 broken, 31-50 significant issues, 51-70 concerning, 71-85 solid, 86-95 very good, 96-100 virtually never). The overall score uses the formula `(average + lowest) / 2` so a single weak dimension drags down the result.

Outputs strengths, weaknesses, a "skeptical senior engineer" take, standards drift details, duplicated patterns, and an "Unverified" section listing what was NOT checked. If the score is below 80, proposes specific improvements and waits for your approval.

A context gate prevents critiques from running without sufficient context — if Claude hasn't read the code, it refuses to score rather than producing false confidence.

### `/devils-advocate:pre`

Pre-task forecast. Run this before starting work to evaluate:

- **Clarity** — Is the request specific enough?
- **Feasibility** — Can an LLM do this well?
- **Risk** — Where are errors most likely?

Checks for project standards (`CLAUDE.md`, `AGENTS.md`, ADRs) and weaves relevant conventions into the ambiguity and pitfall analysis. Lists relevant standards that apply to the upcoming task. Recommends whether to proceed, clarify first, or break into smaller tasks. Gates on whether the task description is detailed enough to forecast against.

### `/devils-advocate:critique-plan <path>`

Plan critique. Point it at a design doc or implementation plan:

```
/devils-advocate:critique-plan docs/plans/my-plan.md
```

Reviews completeness, feasibility, risk spots, gaps, overscoping, security, architecture, and standards compliance (conditional). Discovers project standards and ADRs to check whether the plan aligns with documented conventions. Flags dependency ordering issues and standards drift.

### `/devils-advocate:second-opinion`

Re-critique with a different adversarial lens. Reads the most recent critique from the session log, independently re-scores the same work with a harsher persona ("assume the first critique was too lenient"), then produces a delta report showing where the two critiques agree, diverge, and what the first critique missed. Discovers project standards and checks for existing patterns the code may be duplicating. If standards exist and the first critique didn't check them, that's flagged as a finding.

### `/devils-advocate:log`

Displays the session history of all checks with total count, average score, trend direction, and git SHA linking each check to a specific commit.

## Standards & ADR Awareness

All scoring skills automatically discover your project's documented standards before evaluating:

- **`CLAUDE.md` / `AGENTS.md`** — Read from the project root for conventions, required patterns, and constraints
- **ADR files** — Searched in `docs/adr/`, `docs/decisions/`, `adr/`, `decisions/`, `doc/architecture/decisions/`, and `**/ADR-*.md`
- **Existing patterns** — `critique` and `second-opinion` grep for utilities and helpers the critiqued code might be reinventing

When standards are found, the three post-work skills (`critique`, `critique-plan`, `second-opinion`) add a **Standards Compliance** dimension. Evidence must cite both the standard source and the drifting code, and distinguish between intentional drift (acknowledged deviation with rationale) and accidental drift (convention ignored or unknown).

When no standards are found, the dimension is omitted entirely — no noise. If standards files exist but contain no actionable conventions (just a project description), they're treated as absent.

Projects with 50+ commits and no ADRs get a gentle advisory suggesting they adopt architectural decision records.

## Session Log

Every check is automatically logged to `.devils-advocate/session.md` in your project directory. Each entry includes the git commit SHA at the time of the check, allowing you to correlate scores with specific code states. This file is local to your project and should be gitignored — add `.devils-advocate/` to your `.gitignore`.

## Post-Task Reminder

A hook reminds you to run a critique when Claude finishes responding — but only if there are uncommitted code changes. If the working tree is clean, it stays silent.

## License

MIT
