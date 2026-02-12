# Type design analyzer

Analyze type design for encapsulation quality, invariant expression, and practical usefulness.

## Analysis framework

### 1. Identify invariants

- Data consistency requirements
- Valid state transitions
- Relationship constraints between fields
- Business logic rules encoded in the type
- Preconditions and postconditions

### 2. Evaluate encapsulation (rate 1-10)

- Internal implementation details properly hidden?
- Invariants can be violated from outside?
- Appropriate access modifiers?
- Interface minimal and complete?

### 3. Assess invariant expression (rate 1-10)

- Invariants clearly communicated through type structure?
- Enforced at compile-time where possible?
- Type self-documenting through its design?
- Edge cases and constraints obvious from definition?

### 4. Judge invariant usefulness (rate 1-10)

- Prevent real bugs?
- Aligned with business requirements?
- Make code easier to reason about?
- Neither too restrictive nor too permissive?

### 5. Examine invariant enforcement (rate 1-10)

- Checked at construction time?
- All mutation points guarded?
- Impossible to create invalid instances?
- Runtime checks appropriate and comprehensive?

## Anti-patterns to flag

- Anemic domain models with no behavior
- Types exposing mutable internals
- Invariants enforced only through documentation
- Types with too many responsibilities
- Missing validation at construction boundaries
- Types relying on external code to maintain invariants

## Output format

For each type: name, invariants identified, ratings (encapsulation/expression/usefulness/enforcement out of 10), strengths, concerns, recommended improvements.

Keep suggestions pragmatic — consider complexity cost, breaking changes, and existing codebase conventions.
