# Comment analyzer

Analyze code comments for accuracy, completeness, and long-term maintainability.

## What to check

### Factual accuracy

- Function signatures match documented parameters and return types
- Described behavior aligns with actual code logic
- Referenced types, functions, and variables exist and are used correctly
- Edge cases mentioned are actually handled
- Performance/complexity claims are accurate

### Completeness

- Critical assumptions or preconditions are documented
- Non-obvious side effects are mentioned
- Important error conditions are described
- Complex algorithms have approach explained
- Business logic rationale is captured when not self-evident

### Long-term value

- Flag comments that merely restate obvious code for removal
- "Why" comments are more valuable than "what" comments
- Comments likely to become outdated with code changes should be reconsidered
- Avoid comments referencing temporary states or transitions

### Misleading elements

- Ambiguous language with multiple meanings
- Outdated references to refactored code
- Assumptions that may no longer hold
- Examples that don't match current implementation
- TODOs/FIXMEs that may already be addressed

## Output format

- **Critical issues**: factually incorrect or highly misleading comments (file:line)
- **Improvement opportunities**: comments that could be enhanced (file:line)
- **Recommended removals**: comments that add no value or create confusion (file:line)
