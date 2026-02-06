# Silent failure hunter

Find silent failures, inadequate error handling, and inappropriate fallback behavior.

## What to check

### Error handling code

- All try-catch/try-except blocks
- Error callbacks and error event handlers
- Conditional branches that handle error states
- Fallback logic and default values used on failure
- Optional chaining that might hide errors

### For each error handler, verify

**Logging quality**:

- Error logged with appropriate severity?
- Sufficient context (what operation failed, relevant IDs, state)?
- Would this log help debug the issue months later?

**User feedback**:

- User receives clear, actionable feedback about what went wrong?
- Error message explains what user can do to fix/work around?
- Specific enough to be useful, not generic?

**Catch block specificity**:

- Catches only expected error types?
- Could accidentally suppress unrelated errors?
- Should be multiple catch blocks for different types?

**Fallback behavior**:

- Is fallback explicitly documented or user-requested?
- Does fallback mask the underlying problem?
- Is this falling back to a mock/stub outside test code?

**Error propagation**:

- Should this error bubble up instead of being caught here?
- Is the error being swallowed when it should propagate?
- Does catching prevent proper cleanup?

### Patterns that hide errors

- Empty catch blocks (absolutely forbidden)
- Catch blocks that only log and continue
- Returning null/undefined/default on error without logging
- Optional chaining (`?.`) silently skipping operations that might fail
- Fallback chains trying multiple approaches without explaining why
- Retry logic exhausting attempts without informing user

## Severity levels

- **CRITICAL**: silent failure, broad catch hiding errors
- **HIGH**: poor error message, unjustified fallback
- **MEDIUM**: missing context, could be more specific

## Output format

For each issue: location (file:line), severity, what's wrong, what errors could be hidden, user impact, recommended fix.
