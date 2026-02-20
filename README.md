<p align="center">
  <img src="banner.png" alt="Devil's Advocate" width="100%">
</p>

# devils-advocate

Claude's harshest critic. A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin that scores Claude's work like a skeptical senior engineer — the one who's never impressed, always finds something, and demands receipts for every claim.

## Why

Claude writes code confidently. Too confidently. Left unchecked, it'll tell you everything looks wonderful right up until production catches fire. Inspired by [Confidently Wrong](https://brandon.cc/confidently-wrong).

A [devil's advocate](https://en.wikipedia.org/wiki/Devil%27s_advocate) argues against a position not because they believe the other side, but to surface the holes everyone else missed. This plugin gives Claude that role — the skeptical colleague who says "yeah, but what about..." instead of "LGTM."

A perfect 100 is virtually impossible. "No weaknesses found" is never an acceptable answer. Every score demands `file:line` evidence — no hand-waving, no vibes-based reviews.

## What it catches

It'll flag you for reinventing bcrypt, drifting from your own documented conventions, duplicating a helper that already exists three directories away, and writing plans where step 4 depends on step 7. It knows when you're hand-rolling auth instead of using a battle-tested library, and it won't let you forget that "works on my machine" isn't a testing strategy.

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

Use the full slash command or just ask naturally — Claude will recognize the intent:

| Slash command | Natural language |
|---|---|
| `/devils-advocate:critique` | "critique" |
| `/devils-advocate:pre` | "pre-flight check" |
| `/devils-advocate:critique-plan <path>` | "critique plan docs/plan.md" |
| `/devils-advocate:second-opinion` | "second opinion" |
| `/devils-advocate:log` | "show critique log" |

### `/devils-advocate:critique`

The main event. Post-task adversarial scoring across seven dimensions (plus a conditional eighth). No dimension gets a free pass:

- **Correctness** — Does it actually solve the problem, or does it just look like it does?
- **Completeness** — What edge cases did you miss? What scenarios did you not think about?
- **Assumptions** — What did you assume that nobody stated? Are those assumptions going to age well?
- **Fragility** — Would this survive a slightly different input, or is it held together with duct tape?
- **Security** — Injection vectors, auth gaps, secrets in code, OWASP top 10. No excuses.
- **Testing** — Tests exist? Great. Do they pass? Do they cover more than the happy path? Score 0 if none exist.
- **Architecture** — Separation of concerns, coupling between modules, can you actually deploy and monitor this?
- **Standards Compliance** *(conditional)* — Does the code follow your own documented conventions in `CLAUDE.md`, `AGENTS.md`, or ADRs? Only scored when standards exist; omitted when they don't. No phantom violations.

The overall score uses `(average + lowest) / 2` — one weak dimension drags down the whole result. You don't get to hide behind a high average when your testing score is a 30. Scores below 80 trigger specific, actionable improvement suggestions.

### `/devils-advocate:pre`

Pre-task forecast. Run this before starting work — it'll tell you what's going to go wrong:

- **Clarity** — Is the request specific enough to act on, or are you building on vibes?
- **Feasibility** — Can an LLM actually do this well, or are you setting yourself up for disappointment?
- **Risk Level** — Where are errors most likely to occur? What assumptions will bite you?

Surfaces relevant project standards, flags reinvention risk before you've written a line of code, and recommends whether to proceed, clarify first, or break into smaller tasks. Cheaper to find out now than after 500 lines of code.

### `/devils-advocate:critique-plan <path>`

Point it at a design doc or implementation plan before you build anything:

```
/devils-advocate:critique-plan docs/plans/my-plan.md
```

Scores completeness, feasibility, risk spots, gaps, overscoping, security, architecture, and standards compliance. Catches dependency ordering issues (step 4 needs step 7's output) and plans that propose building solved problems from scratch. Architecture mistakes in the plan phase are 10x more expensive to fix after implementation.

### `/devils-advocate:second-opinion`

Assumes the first critique was too lenient and re-scores from scratch with a harsher lens. Produces a delta report: where the two critiques agree, where they diverge, and what the first one missed. Because the most dangerous critique is the one that let something slide.

### `/devils-advocate:log`

Session history — total checks, average score, trend direction, and git SHA linking each check to a specific commit. Individual critiques are also saved to `.devils-advocate/logs/` so you can reference the full output later.

## Standards & Project Awareness

All skills automatically discover your project's documented standards before scoring. You wrote the rules — this plugin checks if you followed them:

- **`CLAUDE.md` / `AGENTS.md`** — Your conventions, required patterns, and constraints. If you documented it, you'll be scored against it.
- **ADR files** — Searched in `docs/adr/`, `docs/decisions/`, `adr/`, `decisions/`, `doc/architecture/decisions/`, and `**/ADR-*.md`
- **Existing patterns** — Utilities, helpers, and conventions already in your codebase that the critiqued code might be duplicating. Why write it twice?

When standards are found, a **Standards Compliance** dimension is added that distinguishes intentional drift (acknowledged deviations with rationale) from accidental drift (conventions you ignored or didn't know about). When no standards exist, it's omitted entirely — no phantom violations, no noise.

Projects with 50+ commits and no ADRs get a gentle advisory. You've been making architectural decisions — you just haven't been writing them down.

## Reinvention Risk

All skills check whether the work hand-rolls something that has battle-tested libraries — especially in domains where getting it wrong is dangerous:

- **Cryptography** — custom hashing, encryption, token generation. You are not smarter than OpenSSL.
- **Auth** — hand-rolled sessions, JWT, OAuth, password storage. This is how breaches happen.
- **Input sanitization** — custom escaping instead of parameterized queries. Just use the library.
- **Date/time** — manual timezone math, custom parsing. There are entire Wikipedia articles about why this is hard.
- **Validation** — hand-written schemas instead of established validators. You'll miss an edge case.

Even technically correct custom implementations get flagged — correctness today doesn't survive the edge cases that mature libraries have already handled.

## Session Log & Hooks

Every check is logged to `.devils-advocate/session.md` with a git SHA, so you can correlate scores with specific commits. Full critique output is saved to individual files in `.devils-advocate/logs/`. Add `.devils-advocate/` to your `.gitignore`.

A pre-commit hook nudges you to run a critique before committing — the commit still proceeds, it's just a reminder that you're shipping unreviewed work. A plan-file hook suggests running `/devils-advocate:critique-plan` when you write a plan file. Both hooks are configurable via `.devils-advocate/config.json`:

```json
{"hooks": {"pre-commit-warning": false, "plan-file-detect": false}}
```

## License

MIT
