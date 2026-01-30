---
name: address-reviews
description: Handle code reviews from `.review` files. Use when user mentions reviews, review comments, or you find `.review` files in the repository.
---

# Address reviews

Handle code reviews from `.review` files created during local review sessions.

## When to use

- User mentions "reviews", "fix reviews", "address review comments"
- You see `.review` files in the repository
- User asks you to check for review feedback

## Finding review files

```bash
find . -name "*.review" -type f 2>/dev/null
```

## Review file format

Review files are named `<source-file>.review` and placed next to the source file:

- `src/auth.ts` → `src/auth.ts.review`
- `lib/utils.py` → `lib/utils.py.review`

### Structure

```markdown
# Review: filename.ts

**Status:** request-changes | approved | in-progress

## L42 | must-fix

Comment text explaining what needs to be fixed.

## L15-18 | suggestion

Consider this alternative approach.

## L88 | question

Why is this implemented this way?

## L5 | nit

Minor style issue.

## L100 | praise

Nice solution here!
```

### Comment types (priority order)

1. **must-fix** - Blocking issues, fix before proceeding
2. **question** - Need clarification from reviewer, ask before proceeding
3. **suggestion** - Consider implementing, use judgment
4. **nit** - Minor issues, fix if easy
5. **praise** - No action needed, acknowledgment

## Workflow

1. **Find all reviews:**

   ```bash
   find . -name "*.review" -type f
   ```

2. **Read each review file** to understand feedback

3. **Process by priority:**
   - Address all `must-fix` items first
   - For `question` items: If you can't determine the answer from context, ask the user
   - Apply `suggestion` items if they make sense
   - Fix `nit` items if straightforward

4. **After fixing each file:**
   - Delete the `.review` file (it's served its purpose)
   - Or if questions remain, leave the file but note which items are resolved

## Handling questions

When you encounter a `question` type comment:

1. Try to understand the intent from code context
2. If unclear, ask the user directly:

   ```
   Review question at src/auth.ts:88:
   "Why is this timeout 30s?"

   Should I: (a) keep as is, (b) reduce it, (c) make it configurable?
   ```

## After addressing reviews

Once all reviews are addressed:

```bash
# Verify no reviews remain
find . -name "*.review" -type f
```

If empty, reviews are complete. Otherwise, report remaining items.

## Example response

When asked to "fix the reviews":

```
Found 2 review files:
- src/auth.ts.review (2 must-fix, 1 suggestion)
- src/utils.ts.review (1 question)

Addressing src/auth.ts:
- L42 must-fix: Added null check ✓
- L67 must-fix: Fixed error handling ✓
- L15 suggestion: Refactored to use Map ✓

For src/utils.ts:
- L88 question: "Why cache for 1 hour?"
  → Need your input: Should I (a) keep 1 hour, (b) reduce to 15 min, (c) make configurable?
```
