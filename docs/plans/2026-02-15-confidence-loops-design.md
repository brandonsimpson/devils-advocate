# Confidence Loops — Design Document

**Date:** 2026-02-15
**Status:** Approved

## Problem

LLMs produce answers with no built-in mechanism for self-assessment. Users have no way to gauge whether a response is likely correct, complete, or overconfident before acting on it. There is no feedback loop between the LLM's output and a critical evaluation of that output.

## Solution

A Claude Code plugin that calculates confidence scores through adversarial self-review prompts. The plugin bookends tasks with confidence assessments — a pre-task forecast before work begins and a post-task evaluation after completion — and provides on-demand scoring at any point via a slash command.

The LLM becomes its own devil's advocate: it must argue against its own output, identify weaknesses, and surface concerns before presenting a confidence score.

## Architecture

### Plugin Structure

```
confidence-loops/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
├── skills/
│   ├── confidence/
│   │   └── SKILL.md             # On-demand /confidence-loop:confidence
│   ├── confidence-pre/
│   │   └── SKILL.md             # Pre-task assessment (/confidence-loop:confidence-pre)
│   ├── confidence-plan/
│   │   └── SKILL.md             # Plan review (/confidence-loop:confidence-plan)
│   └── confidence-log/
│       └── SKILL.md             # Session log viewer (/confidence-loop:confidence-log)
├── hooks/
│   ├── hooks.json               # Hook configuration
│   └── scripts/
│       └── post-task-reminder.sh # Post-task notification reminder
├── docs/
│   └── plans/                   # Design and implementation documents
└── .gitignore
```

### Sandbox Constraints

All operations are scoped to the user's project directory:

- Session logs write to `.confidence-loop/session.md` within the current working directory
- No writes outside the project boundary
- No network calls or elevated permissions
- No external dependencies — hook script is pure shell
- `.confidence-loop/` directory should be added to `.gitignore` by convention

## Slash Commands

### `/confidence-loop:confidence`

Run a confidence check against the current state of the conversation/solution.

**Assessment dimensions:**
- **Correctness** — Does the solution actually solve the stated problem?
- **Completeness** — Are there gaps, missing edge cases, or unhandled scenarios?
- **Assumptions** — What was assumed that wasn't stated? Are those assumptions valid?
- **Fragility** — Would this break under reasonable variations of the input/requirements?
- **Overconfidence check** — "What would a skeptical senior engineer say about this?"

**Output:** 0-100 confidence score + strengths/weaknesses summary.

**Behavior:** The scoring prompt forces the LLM to identify at least one weakness or concern, even for high-confidence answers. This prevents rubber-stamping.

When the score is below the threshold (default: 80), the plugin lists specific concerns and proposes improvements. The user must approve before any iteration occurs.

### `/confidence-loop:confidence-pre`

Run a pre-task assessment before work begins. Evaluates the task itself, not a solution.

**Assessment dimensions:**
- **Clarity** — Is the prompt specific enough? What's ambiguous?
- **Feasibility** — Is this within the LLM's capabilities? What parts are risky?
- **Predicted pitfalls** — Where are errors most likely? What assumptions are being made?

**Output:** 0-100 confidence forecast + summary of concerns and predicted difficulty.

### `/confidence-loop:confidence-plan <path>`

Run a confidence assessment against a plan file (e.g., a design doc or implementation plan).

**Assessment dimensions:**
- **Completeness** — Does the plan cover all the requirements it claims to?
- **Feasibility** — Are the steps realistic and in the right order? Any missing dependencies?
- **Risk spots** — Which steps are most likely to go wrong or need rework?
- **Gaps** — What does the plan not address that it should?
- **Overscoping** — Is the plan doing more than necessary?

**Output:** 0-100 confidence score + summary. Logged as a "Plan review" check type.

### `/confidence-loop:confidence-log`

Display the session log showing all confidence scores from the current session.

## Hooks & Automation

### Post-task Reminder

A `Notification` hook reminds the user to run a confidence check when Claude finishes a task. The hook script outputs a message suggesting the user invoke `/confidence-loop:confidence`.

The hook is registered in `hooks/hooks.json` and calls `hooks/scripts/post-task-reminder.sh`. It does not auto-run the assessment — the user decides whether to invoke it.

### Pre-task

Pre-task assessment is manual — the user invokes `/confidence-loop:confidence-pre` before starting work. There is no reliable "before first prompt" hook event in Claude Code.

## Session Log

All confidence checks are recorded in `.confidence-loop/session.md` within the project directory.

**Format:**

```markdown
# Confidence Loop Session Log

## Check #1 — Pre-task | 2026-02-15 15:42
- **Score:** 72/100
- **Summary:** Task is clear but involves filesystem operations that may
  behave differently across OS. Risk of edge case gaps.

## Check #2 — Post-task | 2026-02-15 15:58
- **Score:** 85/100
- **Summary:** Solution is correct for the happy path. Weakness: no
  handling for symlinks.
- **Suggestions:** Add symlink detection before path resolution.

## Check #3 — Plan review | 2026-02-15 16:10
- **Score:** 78/100
- **Summary:** Plan covers core features but step 4 depends on step 6
  completing first. Missing error handling strategy.
- **Suggestions:** Reorder steps 4 and 6. Add error handling section.
```

## Scoring Rules

1. Score is 0-100, where 100 = complete confidence in correctness and completeness
2. The LLM must identify at least one weakness or concern regardless of score
3. Score < 80 triggers improvement suggestions presented for user approval
4. User must approve before any corrective iteration occurs (suggest + confirm model)
5. Each check is logged to the session log with timestamp and check type

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Plugin form | Skills + Hooks | Core value is in prompt engineering; skills are the natural fit |
| Skepticism source | Self-review prompts | Avoids extra API costs; keeps it simple |
| Output format | Numeric score + summary | Clear, scannable, actionable |
| Low confidence action | Suggest + confirm | Human stays in the loop |
| Session tracking | Session log in project dir | Sandbox-safe; no global state |
| Pre-task trigger | Manual slash command | No reliable pre-prompt hook exists |
| Post-task trigger | Notification hook | Fires when Claude signals completion; reminds user to run confidence check |
