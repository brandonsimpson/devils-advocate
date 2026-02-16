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

Post-task adversarial critique. Scores the current solution across four dimensions:

- **Correctness** — Does it actually solve the problem?
- **Completeness** — Missing edge cases or gaps?
- **Assumptions** — What was assumed that wasn't stated?
- **Fragility** — Would it break under reasonable input variations?

Outputs a 0-100 score, strengths, weaknesses, and a "skeptical senior engineer" take. If the score is below 80, proposes specific improvements and waits for your approval.

### `/devils-advocate:pre`

Pre-task forecast. Run this before starting work to evaluate:

- **Clarity** — Is the request specific enough?
- **Feasibility** — Can an LLM do this well?
- **Risk** — Where are errors most likely?

Recommends whether to proceed, clarify first, or break into smaller tasks.

### `/devils-advocate:critique-plan <path>`

Plan critique. Point it at a design doc or implementation plan:

```
/devils-advocate:critique-plan docs/plans/my-plan.md
```

Reviews completeness, feasibility, risk spots, gaps, and overscoping. Flags dependency ordering issues.

### `/devils-advocate:log`

Displays the session history of all checks with total count, average score, and trend direction.

## Session Log

Every check is automatically logged to `.devils-advocate/session.md` in your project directory. This file is local to your project and should be gitignored — add `.devils-advocate/` to your `.gitignore`.

## Post-Task Reminder

A notification hook reminds you to run a critique whenever Claude finishes a task. The reminder is passive — it never auto-runs an assessment.

## License

MIT
