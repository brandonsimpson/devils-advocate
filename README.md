# confidence-loop

Self-skeptical confidence scoring for Claude Code. Adversarial self-review prompts that force Claude to argue against its own output, identify weaknesses, and surface concerns before presenting a confidence score.

## Installation

Load the plugin during development:

```bash
claude --plugin-dir /path/to/confidence-loop
```

## Commands

### `/confidence-loop:confidence`

Run a post-task confidence check on the current solution. Scores across correctness, completeness, assumptions, and fragility. Always identifies at least one weakness — "no weaknesses" is never accepted.

When the score is below 80, suggests specific improvements and waits for your approval before acting.

### `/confidence-loop:confidence-pre`

Run a pre-task forecast before work begins. Evaluates clarity, feasibility, and predicted pitfalls. Recommends whether to proceed, clarify first, or break into smaller tasks.

### `/confidence-loop:confidence-plan <path>`

Review a plan file (design doc, implementation plan) as a skeptical technical lead. Checks completeness, feasibility, risk spots, gaps, and overscoping. Flags dependency ordering issues.

```
/confidence-loop:confidence-plan docs/plans/my-plan.md
```

### `/confidence-loop:confidence-log`

Display the session log showing all confidence scores, with a summary of total checks, average score, and trend direction.

## How It Works

Each confidence check:

1. Evaluates the work against specific dimensions (scored 0-100 each)
2. Calculates a weighted overall score anchored to the weakest dimension
3. Identifies at least one genuine weakness or concern
4. Logs the result to `.confidence-loop/session.md` in the project directory
5. If score < 80, proposes improvements and waits for approval

A post-task notification hook reminds you to run a confidence check when Claude finishes a task.

## Session Log

All checks are recorded in `.confidence-loop/session.md` (gitignored by default). Use `/confidence-loop:confidence-log` to view the history and trends.

## License

MIT
