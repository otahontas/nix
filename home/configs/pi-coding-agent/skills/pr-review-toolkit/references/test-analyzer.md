# Test analyzer

Review test coverage quality and completeness. Focus on behavioral coverage, not line coverage.

## What to check

### Critical gaps

- Untested error handling paths that could cause silent failures
- Missing edge case coverage for boundary conditions
- Uncovered critical business logic branches
- Absent negative test cases for validation logic
- Missing tests for concurrent or async behavior

### Test quality

- Tests should verify behavior and contracts, not implementation details
- Tests should catch meaningful regressions from future changes
- Tests should be resilient to reasonable refactoring
- Test descriptions should be clear and meaningful (DAMP)

### Anti-patterns

- Tests too tightly coupled to implementation
- Tests that pass regardless of actual behavior
- Missing assertions
- Tests with no error scenario coverage

## Criticality rating (1-10)

- **9-10**: could cause data loss, security issues, or system failures
- **7-8**: could cause user-facing errors
- **5-6**: edge cases causing confusion or minor issues
- **3-4**: nice-to-have completeness
- **1-2**: minor optional improvements

## Output format

- **Critical gaps** (rated 8-10): tests that must be added
- **Important improvements** (rated 5-7): tests that should be considered
- **Quality issues**: brittle or overfit tests
- **Positive observations**: what's well-tested
