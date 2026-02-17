<p align="center">
  <img src="banner.png" alt="Devil's Advocate" width="100%">
</p>

# devils-advocate

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin that forces Claude to argue against its own output before you ship it.

## Why

Claude is great at writing code. Claude is terrible at criticizing its own code. Left to its own devices, it'll tell you everything looks wonderful right up until production catches fire. Inspired by [Confidently Wrong](https://brandon.cc/confidently-wrong).

A [devil's advocate](https://en.wikipedia.org/wiki/Devil%27s_advocate) argues against a position not because they believe the other side, but to find the holes everyone else missed. This plugin gives Claude that role — the skeptical colleague who says "yeah, but what about..." instead of "LGTM." It's the ultimate critic and feedback loop for your plans, features, and session progress.

It'll catch you reinventing bcrypt, drifting from your own conventions, duplicating a helper that already exists three directories away, and writing plans where step 4 depends on step 7. Every score demands `file:line` evidence — no hand-waving, no vibes-based reviews. A perfect 100 is virtually impossible, and "no weaknesses found" is never an acceptable answer.

It works at every stage: forecasting risk before you start, reviewing plans before you build, critiquing code after you write it, and offering a harsher second opinion when the first critique was too generous.

## Install

```
/plugin marketplace add brandonsimpson/devils-advocate
/plugin install devils-advocate@devils-advocate
```

<details>
<summary>Manual install</summary>

```bash
git clone https://github.com/brandonsimpson/devils-advocate.git ~/.claude/plugins/devils-advocate
```

Add to `~/.claude/settings.json`:

```json
{
  "plugins": [
    "~/.claude/plugins/devils-advocate"
  ]
}
```

Or single session: `claude --plugin-dir ~/.claude/plugins/devils-advocate`

</details>

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
- **Standards Compliance** *(conditional)* — Does the code follow your documented conventions in `CLAUDE.md`, `AGENTS.md`, or ADRs? Only scored when standards exist; omitted otherwise.

Every score requires `file:line` evidence. The overall score uses `(average + lowest) / 2` — one weak dimension drags down the whole result. Scores below 80 trigger suggested improvements.

Before scoring, it also checks for [reinvention risk](#reinvention-risk) and searches for [existing patterns](#standards--project-awareness) the code might be duplicating.

### `/devils-advocate:pre`

Pre-task forecast. Run before starting work:

- **Clarity** — Is the request specific enough to act on?
- **Feasibility** — Can an LLM do this well?
- **Risk Level** — Where are errors most likely?

Surfaces relevant project standards, flags reinvention risk as a predicted pitfall, and recommends whether to proceed, clarify first, or break into smaller tasks.

### `/devils-advocate:critique-plan <path>`

Plan critique. Point it at a design doc or implementation plan:

```
/devils-advocate:critique-plan docs/plans/my-plan.md
```

Scores completeness, feasibility, risk spots, gaps, overscoping, security, architecture, and standards compliance. Flags dependency ordering issues and catches plans that propose building solved problems from scratch.

### `/devils-advocate:second-opinion`

Re-critique with a harsher adversarial lens. Independently re-scores with the mandate "assume the first critique was too lenient," then produces a delta report: where the two critiques agree, where they diverge, and what the first one missed.

### `/devils-advocate:log`

Displays session history — total checks, average score, trend direction, and git SHA linking each check to a specific commit.

## Standards & Project Awareness

All skills automatically discover your project's documented standards before evaluating:

- **`CLAUDE.md` / `AGENTS.md`** — Conventions, required patterns, and constraints
- **ADR files** — Searched in `docs/adr/`, `docs/decisions/`, `adr/`, `decisions/`, `doc/architecture/decisions/`, and `**/ADR-*.md`
- **Existing patterns** — Utilities and helpers the critiqued code might be duplicating within the codebase

When standards are found, a **Standards Compliance** dimension is added that distinguishes intentional drift (acknowledged deviations) from accidental drift (conventions ignored or unknown). When no standards exist, it's omitted entirely — no noise.

Projects with 50+ commits and no ADRs get a gentle advisory.

## Reinvention Risk

All skills check whether the work hand-rolls something that has battle-tested libraries — especially in domains where getting it wrong is dangerous:

- **Cryptography** — custom hashing, encryption, token generation
- **Auth** — hand-rolled sessions, JWT, OAuth, password storage
- **Input sanitization** — custom escaping instead of parameterized queries
- **Date/time** — manual timezone math, custom parsing
- **Validation** — hand-written schemas instead of established validators

Even technically correct custom implementations get flagged — correctness today doesn't survive the edge cases that mature libraries have already handled.

## Session Log & Hooks

Every check is logged to `.devils-advocate/session.md` with a git SHA, so you can correlate scores with specific commits. Add `.devils-advocate/` to your `.gitignore`.

A pre-commit hook warns you to run a critique before `git commit` — the commit still proceeds, it's just a nudge. A plan-file hook suggests running `/devils-advocate:critique-plan` when you write a plan file. Both hooks are configurable via `.devils-advocate/config.json`.

## License

MIT
