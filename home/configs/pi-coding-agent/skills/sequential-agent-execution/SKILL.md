---
name: sequential-agent-execution
description: |
  Complex multi-step refactoring or implementation using sequential pi agents.
  Use when: (1) Task has multiple independent steps that can be isolated,
  (2) Each step requires full context but you want to avoid context pollution,
  (3) Work needs to be coordinated across multiple files or locations,
  (4) You want explicit checkpoints and validation between steps.
  Covers breaking down complex work, using markdown for coordination,
  spawning isolated pi agents, and verifying completion without following details.
---

# Sequential Agent Execution

## Problem

Complex refactoring or implementation tasks can pollute your context window with detailed implementation steps. Following each agent's detailed output makes it hard to maintain the big picture and can lead to confusion when coordinating multiple changes.

## Context / Trigger Conditions

Use this skill when:

- Task involves 5+ independent steps across multiple files
- Each step needs full project context but should be isolated from other steps
- You need explicit validation between steps
- Work requires coordination (e.g., fixing all error handlers, updating all imports)
- You want to maintain overview without getting lost in implementation details

Don't use when:

- Steps are highly interdependent (need sequential context)
- Task is simple enough for single agent session
- Immediate debugging/iteration is needed

## Solution

### 1. Research Phase

First, thoroughly understand the problem:

```bash
# Explore codebase
grep -rn "pattern" .
find . -name "*.ts" | xargs grep -l "issue"

# Identify all locations needing changes
# Document current state and requirements
```

### 2. Create Coordination File

Write a markdown file with:

- Complete context about the task
- All necessary background information
- Explicit, isolated steps (each marked with `❌` or `[ ]`)
- Expected outcome for each step
- Progress tracking section

**Template**:

```markdown
# Task Name

## Context

[All necessary background, file locations, patterns to follow]

## Steps to fix

### Step 1: [Description] ❌

**Location**: [File:Line]
**Current code**: [Code block]
**Problem**: [What's wrong]
**Fix approach**: [How to fix it]
**Expected outcome**: [What success looks like]

### Step 2: [Description] ❌

[...]

## Progress Tracking

- [ ] Step 1: [Description]
- [ ] Step 2: [Description]
      [...]
```

### 3. Sequential Agent Execution

Run agents sequentially **without following output**:

```bash
# For each step, spawn isolated agent
for step in 1 2 3 4 5; do
  echo "=== Step $step ==="

  # Fire agent with minimal, focused prompt
  # Use timeout to prevent hangs
  timeout 60 pi "Fix Step $step from plan.md. Mark as [x] when done." 2>&1 | tail -5

  # Verify step completion
  if grep -q "\[x\] Step $step" plan.md; then
    echo "✓ Step $step complete"
  else
    echo "✗ Step $step failed - stopping"
    exit 1
  fi
done
```

**Key principles**:

- Use `tail` to see only final output, not full agent session
- Each agent reads context from markdown file (fresh start)
- Each agent marks their step complete
- Validate completion before continuing
- Stop immediately if validation fails

### 4. Verification

After all steps:

```bash
# Check all steps marked complete
grep "\[x\]" plan.md | wc -l

# Review actual changes
git diff --stat
git diff [key-file]

# Run tests/checks
npm test  # or whatever validation is appropriate
```

## Verification

Success indicators:

- All checkboxes marked `[x]` in progress tracking
- Git diff shows expected changes
- No compilation/lint errors
- Tests pass (if applicable)

Failure modes:

- Agent doesn't mark step complete → Check markdown clarity
- Agent marks wrong step → Make steps more distinctive
- Changes conflict → Steps weren't truly independent

## Example

Real-world example (fixing silent error handling):

```bash
# 1. Research: Found 12 silent error locations
grep -n "catch.*{}" index.ts
grep -n "return null\|return false" index.ts

# 2. Created fix-silent-errors.md with:
#    - Context about each error location
#    - Specific fix for each (add logging, throw errors, etc.)
#    - Progress tracking with 12 checkboxes

# 3. Sequential execution:
for step in {1..12}; do
  timeout 50 pi "Fix Step $step from fix-silent-errors.md. Mark as [x]." 2>&1 | tail -20

  if ! grep -q "\[x\] Step $step" fix-silent-errors.md; then
    echo "Step $step failed"
    exit 1
  fi
done

# 4. Verification:
git diff --stat  # 258 insertions, 208 deletions
```

Result: 12 independent fixes completed with minimal context pollution.

## Notes

**Why this works**:

- Each agent starts fresh with full context from markdown
- No context pollution from previous steps
- Explicit validation prevents cascading failures
- You maintain big picture without implementation details

**When to stop following output**:

- Use `tail -N` to see only final lines
- Or redirect to log: `pi "..." > /tmp/step.log 2>&1`
- Only check: (1) exit code, (2) checkbox marked

**Markdown as coordination**:

- Single source of truth for all agents
- Explicit checkboxes for validation
- Contains all context needed
- Can be committed for documentation

**Limitations**:

- Doesn't work for exploratory/iterative work
- Requires upfront planning time
- Steps must be truly independent
- Can't debug individual step failures in real-time

## References

- This skill was extracted from fixing silent error handling in piception extension
- Related pattern: "Rubber duck debugging" but with isolated agents
- Similar to CI/CD pipelines with explicit stages and validation
