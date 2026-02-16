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

Post-task adversarial critique. Scores the current solution across seven dimensions:

- **Correctness** — Does it actually solve the problem?
- **Completeness** — Missing edge cases or gaps?
- **Assumptions** — What was assumed that wasn't stated?
- **Fragility** — Would it break under reasonable input variations?
- **Security** — Injection vectors, auth/authz issues, secrets in code, OWASP top 10
- **Testing** — Do tests exist? Do they pass? What code paths lack coverage?
- **Architecture** — Separation of concerns, coupling, scalability, operational readiness

Every score must cite specific code references (`file:line`) as evidence. Scores without evidence are not permitted. Outputs a 0-100 score, strengths, weaknesses, a "skeptical senior engineer" take, and an "Unverified" section listing what was NOT checked. If the score is below 80, proposes specific improvements and waits for your approval.

A context gate prevents critiques from running without sufficient context — if Claude hasn't read the code, it refuses to score rather than producing false confidence.

### `/devils-advocate:pre`

Pre-task forecast. Run this before starting work to evaluate:

- **Clarity** — Is the request specific enough?
- **Feasibility** — Can an LLM do this well?
- **Risk** — Where are errors most likely?

Recommends whether to proceed, clarify first, or break into smaller tasks. Gates on whether the task description is detailed enough to forecast against.

### `/devils-advocate:critique-plan <path>`

Plan critique. Point it at a design doc or implementation plan:

```
/devils-advocate:critique-plan docs/plans/my-plan.md
```

Reviews completeness, feasibility, risk spots, gaps, overscoping, security, and architecture. Flags dependency ordering issues.

### `/devils-advocate:second-opinion`

Re-critique with a different adversarial lens. Reads the most recent critique from the session log, independently re-scores the same work with a harsher persona ("assume the first critique was too lenient"), then produces a delta report showing where the two critiques agree, diverge, and what the first critique missed.

### `/devils-advocate:log`

Displays the session history of all checks with total count, average score, trend direction, and git SHA linking each check to a specific commit.

## Session Log

Every check is automatically logged to `.devils-advocate/session.md` in your project directory. Each entry includes the git commit SHA at the time of the check, allowing you to correlate scores with specific code states. This file is local to your project and should be gitignored — add `.devils-advocate/` to your `.gitignore`.

## Post-Task Reminder

A hook reminds you to run a critique when Claude finishes responding — but only if there are uncommitted code changes. If the working tree is clean, it stays silent.

## License

MIT
