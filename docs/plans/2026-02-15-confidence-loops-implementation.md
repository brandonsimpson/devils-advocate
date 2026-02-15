# Confidence Loops Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a Claude Code plugin that provides self-skeptical confidence scoring through adversarial self-review prompts, with on-demand slash commands and automated post-task hooks.

**Architecture:** A pure Claude Code plugin composed of skill files (markdown prompts), a hooks configuration, and a minimal shell script. All assessment logic lives in the skill prompts. Session state is tracked in a `.confidence-loop/session.md` file scoped to the user's project directory.

**Tech Stack:** Claude Code plugin system (skills, hooks), shell script (POSIX sh), markdown

---

### Task 1: Create plugin scaffold

**Files:**
- Create: `.claude-plugin/plugin.json`

**Step 1: Create the plugin manifest**

```json
{
  "name": "confidence-loop",
  "description": "Self-skeptical confidence scoring for Claude Code — adversarial self-review prompts that calculate confidence scores before, during, and after tasks",
  "version": "1.0.0",
  "author": {
    "name": "Brandon Simpson"
  },
  "license": "MIT",
  "keywords": ["confidence", "scoring", "self-review", "quality", "assessment"]
}
```

**Step 2: Create directory structure**

Run:
```bash
mkdir -p skills/confidence
mkdir -p skills/confidence-pre
mkdir -p skills/confidence-plan
mkdir -p skills/confidence-log
mkdir -p hooks/scripts
```

**Step 3: Commit**

```bash
git add .claude-plugin/plugin.json
git commit -m "feat: add plugin manifest and directory structure"
```

---

### Task 2: Create the confidence check skill (on-demand assessment)

This is the core skill — the main `/confidence-loop:confidence` slash command that evaluates the current solution.

**Files:**
- Create: `skills/confidence/SKILL.md`

**Step 1: Write the skill file**

The skill file contains the adversarial self-review prompt with scoring rubric, output format, session log writing instructions, and the threshold-based suggestion behavior.

`skills/confidence/SKILL.md`:

~~~markdown
---
name: confidence
description: Use when the user asks to "check confidence", "run confidence check", "assess solution", "how confident are you", "score this answer", "evaluate accuracy", "rate your confidence", "scrutinize this", or invokes /confidence-loop:confidence. Provides adversarial self-review of the current solution.
---

# Confidence Check

You are running a **confidence assessment** on your current work. You must be your own harshest critic. Do NOT rubber-stamp your own output.

## Process

1. **Identify the original task** — What was the user's original request or problem? State it clearly.

2. **Evaluate against these dimensions** — Score each 0-100:

   - **Correctness** — Does the solution actually solve the stated problem? Are there logical errors, wrong assumptions, or incorrect outputs?
   - **Completeness** — Are there gaps, missing edge cases, or unhandled scenarios? Does it cover everything the user asked for?
   - **Assumptions** — What was assumed that wasn't explicitly stated? Are those assumptions valid? List each assumption.
   - **Fragility** — Would this break under reasonable variations of the input or requirements? How brittle is it?
   - **Overconfidence check** — What would a skeptical senior engineer say about this? What's the most likely criticism?

3. **Identify at least one weakness** — Even if your confidence is high, you MUST identify at least one genuine concern, risk, or weakness. "No weaknesses" is never an acceptable answer.

4. **Calculate overall score** — Weighted average of dimensions. The overall score should reflect the weakest dimension — a chain is only as strong as its weakest link. A score of 100 should be virtually impossible.

5. **Write the session log entry** — Use the Write tool to append to `.confidence-loop/session.md` in the project root. Create the directory and file if they don't exist. Use this format:

   ```markdown
   ## Check #N — Post-task | YYYY-MM-DD HH:MM
   - **Score:** XX/100
   - **Summary:** [2-3 sentence summary of strengths and weaknesses]
   - **Suggestions:** [Only if score < 80: specific improvements proposed]
   ```

   Increment the check number based on existing entries in the file.

## Output Format

Present your assessment to the user in this format:

```
CONFIDENCE ASSESSMENT
═══════════════════════════════════════

Original task: [restate the task in one line]

Correctness:    XX/100 — [one-line justification]
Completeness:   XX/100 — [one-line justification]
Assumptions:    XX/100 — [one-line justification]
Fragility:      XX/100 — [one-line justification]

Overall Score:  XX/100

Strengths:
• [strength 1]
• [strength 2]

Weaknesses:
• [weakness 1 — REQUIRED, always at least one]
• [weakness 2 if applicable]

Skeptical Take: [What a skeptical senior engineer would say]
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

- Be genuinely critical, not performatively critical
- A score of 95+ should be rare and reserved for trivially simple, well-tested solutions
- Anchor your criticisms in specific, concrete concerns — not vague "could be better"
- If you realize your solution has a genuine flaw during assessment, say so clearly
- Never skip the session log write
~~~

**Step 2: Verify the file was created correctly**

Run: `cat skills/confidence/SKILL.md | head -5`
Expected: Shows the YAML frontmatter starting with `---`

**Step 3: Commit**

```bash
git add skills/confidence/SKILL.md
git commit -m "feat: add core confidence check skill with adversarial self-review"
```

---

### Task 3: Create the pre-task assessment skill

The `/confidence-loop:confidence-pre` slash command that forecasts task difficulty before work begins.

**Files:**
- Create: `skills/confidence-pre/SKILL.md`

**Step 1: Write the skill file**

`skills/confidence-pre/SKILL.md`:

~~~markdown
---
name: confidence-pre
description: Use when the user asks to "assess before starting", "pre-task check", "forecast difficulty", "can you handle this", "how hard is this", "predict confidence", or invokes /confidence-loop:confidence-pre. Provides a pre-flight assessment before work begins.
---

# Pre-Task Confidence Forecast

You are running a **pre-task assessment** to forecast how likely you are to complete the upcoming task accurately. Evaluate the task BEFORE doing any work. Be honest about your limitations.

## Process

1. **Restate the task** — What is the user asking you to do? Be precise.

2. **Evaluate clarity:**
   - Is the task specific enough to act on?
   - What is ambiguous or underspecified?
   - What questions SHOULD be asked before starting?

3. **Evaluate feasibility:**
   - Is this within your capabilities as an LLM?
   - What parts are you confident about?
   - What parts are risky or at the edge of your ability?
   - Does this require information you might not have?

4. **Predict pitfalls:**
   - Where are errors most likely to occur?
   - What assumptions will you need to make?
   - What are the most common mistakes for this type of task?
   - What would cause a complete failure vs. a partial success?

5. **Calculate confidence forecast** — Score 0-100. This is a PREDICTION, not a post-hoc evaluation. Be conservative. Weight feasibility and pitfall risk heavily.

6. **Write the session log entry** — Use the Write tool to append to `.confidence-loop/session.md` in the project root. Create the directory and file if they don't exist:

   ```markdown
   ## Check #N — Pre-task | YYYY-MM-DD HH:MM
   - **Score:** XX/100
   - **Summary:** [2-3 sentence forecast of difficulty and risks]
   ```

## Output Format

```
PRE-TASK CONFIDENCE FORECAST
═══════════════════════════════════════

Task: [restate the task]

Clarity:      XX/100 — [is the request specific enough?]
Feasibility:  XX/100 — [can this be done well by an LLM?]
Risk Level:   XX/100 — [how likely are significant errors?]

Forecast:     XX/100

Ambiguities:
• [anything unclear or underspecified]

Predicted Pitfalls:
• [where errors are most likely]
• [assumptions that may be wrong]

Recommendation: [proceed / clarify first / break into smaller tasks]
```

## Rules

- This runs BEFORE any work is done — do not start solving the task
- Be conservative with scores — overconfidence at this stage is the worst outcome
- If clarity is below 60, recommend the user clarify before proceeding
- If feasibility is below 50, say so honestly and suggest alternatives
- Never skip the session log write
~~~

**Step 2: Verify the file**

Run: `cat skills/confidence-pre/SKILL.md | head -5`
Expected: Shows the YAML frontmatter

**Step 3: Commit**

```bash
git add skills/confidence-pre/SKILL.md
git commit -m "feat: add pre-task confidence forecast skill"
```

---

### Task 4: Create the plan review skill

The `/confidence-loop:confidence-plan` slash command that scrutinizes plan files.

**Files:**
- Create: `skills/confidence-plan/SKILL.md`

**Step 1: Write the skill file**

`skills/confidence-plan/SKILL.md`:

~~~markdown
---
name: confidence-plan
description: Use when the user asks to "review a plan", "check plan confidence", "assess this plan", "scrutinize the plan", "evaluate implementation plan", or invokes /confidence-loop:confidence-plan. Provides adversarial review of a plan document.
---

# Plan Confidence Review

You are running a **plan review assessment**. Read the specified plan file and scrutinize it as a skeptical technical lead would before approving it for implementation.

## Process

1. **Read the plan file** — The user should provide a path as an argument (e.g., `/confidence-loop:confidence-plan docs/plans/my-plan.md`). If no path is provided, ask for one. Use the Read tool to read the file.

2. **Evaluate against these dimensions** — Score each 0-100:

   - **Completeness** — Does the plan cover all requirements it claims to? Are there missing steps or unaddressed concerns?
   - **Feasibility** — Are the steps realistic and in the right order? Are there missing dependencies between steps?
   - **Risk spots** — Which steps are most likely to go wrong or need rework? Where are the unknowns?
   - **Gaps** — What does the plan NOT address that it should? Missing error handling? Missing tests? Missing edge cases?
   - **Overscoping** — Is the plan doing more than necessary? Are there YAGNI violations?

3. **Identify dependency issues** — Are steps ordered correctly? Does any step depend on something that comes later?

4. **Calculate overall score** — Conservative weighted average. Plans with dependency ordering issues or missing steps should score below 70.

5. **Write the session log entry** — Append to `.confidence-loop/session.md`:

   ```markdown
   ## Check #N — Plan review | YYYY-MM-DD HH:MM
   - **Plan:** [filename]
   - **Score:** XX/100
   - **Summary:** [2-3 sentence assessment]
   - **Suggestions:** [specific improvements if score < 80]
   ```

## Output Format

```
PLAN CONFIDENCE REVIEW
═══════════════════════════════════════

Plan: [filename]

Completeness:  XX/100 — [covers requirements?]
Feasibility:   XX/100 — [steps realistic and ordered?]
Risk Spots:    XX/100 — [where will things go wrong?]
Gaps:          XX/100 — [what's missing?]
Overscoping:   XX/100 — [doing too much?]

Overall Score: XX/100

Strengths:
• [what the plan does well]

Concerns:
• [specific issues found]

Dependency Issues:
• [any ordering problems — or "None found"]

Suggestions:
1. [specific improvement]
2. [specific improvement]
```

## Rules

- Read the ENTIRE plan before scoring — do not skim
- Check step ordering carefully — dependency issues are the most common plan flaw
- Be especially critical of missing error handling and testing strategies
- A plan that says "add tests" without specifying WHAT to test should score low on completeness
- Never skip the session log write
~~~

**Step 2: Verify the file**

Run: `cat skills/confidence-plan/SKILL.md | head -5`
Expected: Shows the YAML frontmatter

**Step 3: Commit**

```bash
git add skills/confidence-plan/SKILL.md
git commit -m "feat: add plan review confidence skill"
```

---

### Task 5: Create the session log viewer skill

The `/confidence-loop:confidence-log` slash command that displays the session history.

**Files:**
- Create: `skills/confidence-log/SKILL.md`

**Step 1: Write the skill file**

`skills/confidence-log/SKILL.md`:

~~~markdown
---
name: confidence-log
description: Use when the user asks to "show confidence log", "view confidence history", "show scores", "confidence session log", or invokes /confidence-loop:confidence-log. Displays the running session log of all confidence checks.
---

# Confidence Session Log Viewer

Display the confidence assessment history for this session.

## Process

1. **Read the session log** — Use the Read tool to read `.confidence-loop/session.md` from the project root.

2. **If the file doesn't exist or is empty** — Report that no confidence checks have been run yet and suggest available commands:
   - `/confidence-loop:confidence` — Assess current solution
   - `/confidence-loop:confidence-pre` — Pre-task forecast
   - `/confidence-loop:confidence-plan <path>` — Review a plan file

3. **If the file exists** — Display its contents and add a brief summary:
   - Total number of checks run
   - Average score across all checks
   - Trend (improving, declining, or stable)
   - Lowest-scoring check (the one that needs most attention)

## Output Format

```
CONFIDENCE SESSION LOG
═══════════════════════════════════════

[contents of .confidence-loop/session.md]

───────────────────────────────────────
Summary: N checks | Avg: XX/100 | Trend: [improving/declining/stable]
Lowest:  Check #X (XX/100) — [brief note]
```

## Rules

- Just display and summarize — do not re-run any assessments
- If the log is very long (>20 entries), show the last 10 and mention how many were omitted
- Never modify the session log file in this skill
~~~

**Step 2: Verify the file**

Run: `cat skills/confidence-log/SKILL.md | head -5`
Expected: Shows the YAML frontmatter

**Step 3: Commit**

```bash
git add skills/confidence-log/SKILL.md
git commit -m "feat: add confidence session log viewer skill"
```

---

### Task 6: Create the post-task hook

A `Notification` hook that reminds the user to run a confidence check when a task completes.

**Files:**
- Create: `hooks/hooks.json`
- Create: `hooks/scripts/post-task-reminder.sh`

**Step 1: Write the hook configuration**

`hooks/hooks.json`:

```json
{
  "hooks": {
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/post-task-reminder.sh"
          }
        ]
      }
    ]
  }
}
```

**Step 2: Write the hook script**

`hooks/scripts/post-task-reminder.sh`:

```sh
#!/bin/sh
# Post-task reminder to run confidence assessment
# Sandbox-safe: no writes, no network, just output

echo ""
echo "Confidence Loop: Task complete. Run /confidence-loop:confidence to assess this solution."
echo ""
```

**Step 3: Make the script executable**

Run: `chmod +x hooks/scripts/post-task-reminder.sh`

**Step 4: Verify the hook config is valid JSON**

Run: `python3 -c "import json; json.load(open('hooks/hooks.json')); print('Valid JSON')"`
Expected: `Valid JSON`

**Step 5: Commit**

```bash
git add hooks/hooks.json hooks/scripts/post-task-reminder.sh
git commit -m "feat: add post-task notification hook with reminder"
```

---

### Task 7: Add .gitignore for session logs

Ensure `.confidence-loop/` directories in user projects don't get committed.

**Files:**
- Create: `.gitignore`

**Step 1: Write the .gitignore**

`.gitignore`:

```
# Confidence Loop session data (generated in user projects)
.confidence-loop/
```

**Step 2: Commit**

```bash
git add .gitignore
git commit -m "chore: add .gitignore for session log directory"
```

---

### Task 8: Manual integration test

Verify the plugin works end-to-end by installing it locally and running each skill.

**Step 1: Verify plugin structure**

Run: `find . -type f | sort | grep -v '.git/'`

Expected output should include:
```
./.claude-plugin/plugin.json
./.claude/settings.local.json
./.gitignore
./docs/plans/2026-02-15-confidence-loops-design.md
./docs/plans/2026-02-15-confidence-loops-implementation.md
./hooks/hooks.json
./hooks/scripts/post-task-reminder.sh
./skills/confidence/SKILL.md
./skills/confidence-log/SKILL.md
./skills/confidence-plan/SKILL.md
./skills/confidence-pre/SKILL.md
```

**Step 2: Verify plugin.json is valid**

Run: `python3 -c "import json; json.load(open('.claude-plugin/plugin.json')); print('Valid')"`
Expected: `Valid`

**Step 3: Verify hooks.json is valid**

Run: `python3 -c "import json; json.load(open('hooks/hooks.json')); print('Valid')"`
Expected: `Valid`

**Step 4: Verify hook script is executable**

Run: `test -x hooks/scripts/post-task-reminder.sh && echo 'Executable' || echo 'NOT executable'`
Expected: `Executable`

**Step 5: Run the hook script to verify output**

Run: `./hooks/scripts/post-task-reminder.sh`
Expected: Shows the reminder message containing "Confidence Loop: Task complete."

**Step 6: Test plugin loading**

Load the plugin locally using the `--plugin-dir` flag:

```bash
claude --plugin-dir /path/to/confidence-loop
```

Then verify in the session that:
- `/confidence-loop:confidence` appears as an available skill
- `/confidence-loop:confidence-pre` appears as an available skill
- `/confidence-loop:confidence-plan` appears as an available skill
- `/confidence-loop:confidence-log` appears as an available skill

Run each skill and confirm it produces the expected output format.

**Step 7: Commit any fixes**

If any issues were found and fixed during testing, commit them.
